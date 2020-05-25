classdef ArrayType < ott.beam.properties.Beam
% A mix-in type for beams that have internal arrays of beams.
% TODO: Review if this should inherit from properties.Beam
% TODO: Review this whole file
%
% Properties
%   - array_type    -- Type of array ('coherent', 'array' or 'incoherent')
%
% Methods
%   - plus          -- Provides addition of coherent beams
%   - cat           -- Concatenation of beams and arrays
%   - vertcat       -- Vertical concatenation of beams and arrays
%   - horzcat       -- Horizontal concatenation of beams and arrays
%   - subsref       -- For direct indexing of the beams array
%   - isempty       -- Returns true if the beam array is empty
%   - arrayApply    -- Apply function to beam array output
%   - combineIncoherentArray  -- Combine cell array of beam data
%   - translateXyzInternal    -- Overload for RotationPositionEntity
%
% Static methods
%   - empty         -- Create an empty array (should be overloaded)
%
% Abstract methods
%   - plusInternal    -- Called by plus when combination is needed
%   - catInternal     -- Called by cat when combination is needed
%   - subsrefInternal -- Called by subsref for beam subscripting
%   - size            -- Size of the beam array

% Copyright 2020 Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file.

  properties
    array_type     % Type of array ('coherent', 'array' or 'incoherent')
  end

  methods (Abstract, Hidden)
    subsasgnInternal  % Called by subsasgn for beam subscripting
    subsrefInternal   % Called by subsref for beam subscripting
    plusInternal      % Called by plus when combination is needed
    catInternal       % Called by horzcat when combination is needed
    size              % Get the size of the beam array
  end

  methods (Static)
    function beam = empty(varargin)
      % Construct an empty beam array
      %
      % This function should be overloaded by the sub-class to describe
      % what an empty array looks like for your type.

      warning(['Constructing a ott.beam.abstract.Array', newline, ...
        'This method should be overloaded by your sub-class']);

      sz = [0, 0];
      beam = ott.beam.abstract.Array('array', sz);
    end
  end

  methods
    function beam = ArrayType(varargin)
      % Construct a new array type beam
      %
      % Optional named arguments:
      %   - array_type (enum) -- Initial value for array_type.
      %     Default: ``'array'``.

      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('array_type', 'array');
      p.parse(varargin{:});
      unmatched = ott.utils.unmatchedArgs(p);

      beam = beam@ott.beam.properties.Beam(unmatched{:});
      beam.array_type = p.Results.array_type;
    end

    function beam = plus(b1, b2)
      % Implementation of the addition operator for adding coherent beams.
      %
      % Beam inputs must be regular beams, beam arrays or coherent.
      % If beams are incoherent beam arrays, raises an error.
      %
      % If the beam types differ or the arrays have different array types,
      % creates a new coherent beam array.  Otherwise, calls ``plusInternal``
      % with the beams.
      %
      % Usage
      %   beam = beam1 + beam2

      % Check we have beams
      assert(isa(b1, 'ott.beam.abstract.Beam'), 'beam1 must be a beam');
      assert(isa(b2, 'ott.beam.abstract.Beam'), 'beam2 must be a beam');
      
      % Check mediums match
      assert(b1.medium == b2.medium, ...
        'mediums must match for coherent addition');

      % Check they are not incoherent
      if isa(b1, 'ott.beam.utils.ArrayType')
        assert(~strcmpi(b1.array_type, 'incoherent'), ...
          'ott:beam:utils:ArrayType:plus_incoherent', ...
          'beam1 must not be incoherent');
      end
      if isa(b2, 'ott.beam.utils.ArrayType')
        assert(~strcmpi(b2.array_type, 'incoherent'), ...
          'ott:beam:utils:ArrayType:plus_incoherent', ...
          'beam1 must not be incoherent');
      end

      % Determine if we need a new array or call plusInternal
      if strcmpi(class(b1), class(b2)) ...
          && isa(b1, 'ott.beam.utils.ArrayType') ...
          && strcmpi(b1.array_type, 'coherent') ...
          && strcmpi(b2.array_type, 'coherent')
        beam = plusInternal(b1, b2);
      else
        beam = catNewArray('coherent', [1, 2], b1, b2);
      end
    end

    function beam = horzcat(varargin)
      % Concatenate beam objects.
      %
      % Usage
      %   beam = [beam1, beam2, ...]
      %   Defers to cat(2, ...).

      beam = cat(2, varargin{:});
    end

    function beam = vertcat(varargin)
      % Concatenate beam objects.
      %
      % Usage
      %   beam = [beam1; beam2; ...]
      %   Defers to cat(1, ...).

      beam = cat(1, varargin{:});
    end

    function beam = cat(dim, varargin)
      % Concatenate beam objects.
      %
      % When concatenating arrays, incoherent arrays can contain
      % coherent arrays, but coherent arrays can't contain incoherent arrays.
      %
      % If the classes are the same and the array types match, calls
      % catInternal, otherwise creates a new beam array.
      %
      % Usage
      %   beam = cat(dim, beam1, beam2, beam3, ...)
      
      % Remove all inputs that are ott.beam.abstract.Empty
      mask = false(size(varargin));
      for ii = 1:length(varargin)
        mask(ii) = isa(varargin{ii}, 'ott.beam.abstract.Empty');
      end
      varargin(mask) = [];

      allSameType = true;
      dim_size = size(varargin{1});   % Compare all dimensions except dim
      dim_size(dim) = 0;
      class_type = class(varargin{1});
      array_type = [];
      medium = varargin{1}.medium;

      % Check we have beams
      for ii = 1:length(varargin)
        assert(isa(varargin{ii}, 'ott.beam.Beam'), ...
            'beams must inherit from ott.beam.abstract.Beam');

        if isa(varargin{ii}, 'ott.beam.utils.ArrayType')

          if isempty(array_type)
            array_type = varargin{ii}.array_type;
          else
            allSameType = allSameType ...
                & strcmpi(varargin{ii}.array_type, array_type);
          end
        end

        % Check same type
        allSameType = allSameType ...
            & strcmpi(class_type, class(varargin{ii}));
          
        % Check same medium
        allSameType = allSameType ...
            & varargin{ii}.medium == medium;

        % Check same size in dimension
        allSameType = allSameType ...
            & sum(size(varargin{ii}) ~= dim_size) <= 1;
      end

      if allSameType && ~isempty(array_type)
        beam = catInternal(dim, varargin{:});
      else
        sz = ones(1, dim+1);
        sz(dim) = numel(varargin);
        beam = catNewArray('array', sz, varargin{:});
      end
    end

    function num = numel(beam)
      % Get the number of elements in the beam
      %
      % Usage
      %   num = numel(beam) or   num = beam.numel()
      %
      % Default behaviour: ``prod(size(beam))``

      num = prod(size(beam));
    end

    function b = isempty(beam)
      % Returns true if the beam is empty
      %
      % Usage
      %   b = isempty(beam)     or    b = beam.isempty()
      
      b = numel(beam) == 0;
    end
    
    function n = numArgumentsFromSubscript(obj,s,indexingContext)
      % Specify the number of output arguments
      if indexingContext == matlab.mixin.util.IndexingContext.Assignment
        n = length(s(1).subs{:});
      else
        n = 1;
      end
    end

    function varargout = subsref(obj, s)
      % Implement array subscripts for beams in this array
      
      % Declare an ismethod function which checks hidden methods
      methodlist = @(metacls) {metacls.MethodList.Name};
      ismethod = @(obj, name) any(strcmpi(name, methodlist(metaclass(obj))));

      switch s(1).type
        case '.'
          % Seems that we need to apply subsref to parts one at a time,
          % we can't just dispatch to a built-in subsref (for example,
          % for cell indexing).  Can't do subsref(obj.(s(1).subs), s(2:end))
          if length(s) > 1 && ~ismethod(obj, s(1).subs)
            
            % Get field of array
            part = obj.(s(1).subs);
            
            % Iterate over remaining terms
            for ii = 2:length(s)-1
              
              % Methods consume two arguments
              if ismethod(part, s(ii).subs)
                break;
              end
              
              % This should call subsref on array beams as intended
              % Assumes single outputs of intermediate (is this ok?)
              part = subsref(part, s(ii));
            end
            
            if length(s) >= 3 && ismethod(part, s(ii).subs)
              % Call method using default subsref
              [varargout{1:nargout}] = builtin('subsref',obj,s(ii:end));
            else
              % Access final argument (with all outputs)
              [varargout{1:nargout}] = subsref(part, s(end));
            end
          else
            % Default behaviour (for imediate properties)
            [varargout{1:nargout}] = builtin('subsref',obj,s);
          end
        case '()'
          if length(s) >= 1 % obj(indices)
            % obj(indices) -> obj.beams(indices)
            beams = obj.subsrefInternal(s(1).subs);

            if length(s) > 1
              [varargout{1:nargout}] = subsref(beams,s(2:end));
            else
              varargout{1} = beams;
            end
          else
            % Use built-in for any other expression
            [varargout{1:nargout}] = builtin('subsref',obj,s);
          end
        case '{}'
          % Default behaviour
          [varargout{1:nargout}] = builtin('subsref',obj,s);
        otherwise
          error('Not a valid indexing expression')
      end
    end
    
    function obj = subsasgn(obj,s,varargin)
      
      switch s(1).type
        case '.'
          if length(s) > 1
            % Use child subsref (in case child has its own)
            obj.(s(1).subs) = subsasgn(obj.(s(1).subs), s(2:end), varargin{:});
          else
            % Default behaviour
            obj = builtin('subsasgn',obj,s,varargin{:});
          end
        case '()'
          if length(s) >= 1 % obj(indices)
            % obj(indices) -> obj.beams(indices)
            obj = obj.subsasgnInternal(s(1).subs, s(2:end), varargin{:});
            
          else
            % Call built-in for any other case
            obj = builtin('subsasgn',obj,s,varargin{:});
          end
        case '{}'
          % Call built-in for any case
          obj = builtin('subsasgn',obj,s,varargin{:});
        otherwise
          error('Not a valid indexing expression')
      end
    end
    
    function data = arrayApply(beam, func, varargin)
      % Apply function to each array in the beam array output.
      %
      % Usage
      %   data = beam.arrayApply(func, ...)
      %   Additional parameters are passed to the function.
      %
      % This default implemenataion applies the function to
      % each cell in data if the beam is not coherent.
      
      % TODO: Shouldn't this use beam?
      
      if iscell(varargin{1})
        % Apply visualisatio funtion to sub-beams
        data = cell(size(varargin{1}));
        for ii = 1:numel(varargin{1})
          sub_data = cellfun(@(x) x{ii}, varargin, 'UniformOutput', false);
          data{ii} = func(sub_data{:});
        end
      else
        data = func(varargin{:});
      end
    end

    function arr = combineIncoherentArray(beam, arr, dim)
      % Combine incoherent layers of an array
      %
      % Usage
      %   arr = beam.combineIncoherentArray(arr, dim)
      %
      % Parametesrs
      %   - arr -- Cell arary of arrays to combine.
      %   - dim -- Dimension to combine along.  If the array data is
      %     3x1 vectors, set dim to 2.

      % Check if we have work to do
      if strcmpi(beam.array_type, 'coherent') || ~iscell(arr)
        return;
      end

      % Combine this layer incoherently
      if strcmpi(beam.array_type, 'incoherent')
        oldArr = arr;
        arr = arr{1};
        for ii = 2:numel(oldArr)
          arr = sum(cat(dim, arr, oldArr{ii}), dim);
        end
      end
    end
  end

  methods (Hidden)
    function obj = translateXyzInternal(obj, xyz, varargin)
      % Apply translations to position property.
      %
      % Raises an error if more than one translation.
      % If your ArrayType supports more than one translation, overload
      % this method.

      if size(xyz, 2) > 1
        error('Too many positions to apply to beam array');
      end

      p = inputParser;
      p.addParameter('origin', 'global');
      p.parse(varargin{:});

      switch p.Results.origin
        case 'global'
          obj.position = obj.position + xyz;
        case 'local'
          obj.position = obj.position + obj.rotation*xyz;
        otherwise
          error('Unknown origin for translation');
      end
    end
  end

  methods % Getters/setters
    function beam = set.array_type(beam, val)

      % Check valid value
      assert(any(strcmpi(val, {'coherent', 'array', 'incoherent'})), ...
        'array_type must be one of ''cohereht'', ''array'', ''incohereht''');

      % Check array contains no incoherent values
      if strcmpi(val, 'coherent') && isa(beam, 'ott.beam.abstract.Array')
        assert(~beam.contains_incoherent, ...
          'ott:beam:utils:ArrayType:coherent_with_incoherent', ...
          'Cannot have coherent array of incoherent beams');
      end

      beam.array_type = val;
    end
  end
end