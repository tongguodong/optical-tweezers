classdef Tmatrix
%Tmatrix abstract class representing T-matrix of a scattering particle
%
% Tmatrix properties:
%   data          The T-matrix this class encapculates
%   type          Type of T-matrix (total or scattered)
%
% Tmatrix methods:
%
% Static methods:
%   simple        Construct a simple particle T-matrix
%
% Abstract methods:
%
% This file is part of the optical tweezers toolbox.
% See LICENSE.md for information about using/distributing this file.

  properties (SetAccess=protected)
    data          % The matrix this class encapsulates
  end

  properties (Access=private)
    type_         % Type of T-matrix (actual value)
  end

  properties (Dependent)
    Nmax          % Current size of T-matrix
    type          % Type of T-matrix (total or scattered)
  end

  methods (Static)
    function tmatrix = simple(shape, varargin)
      %SIMPLE constructs a T-matrix for a bunch of simple particles
      % This method creates an instance of one of the other T-matrix
      % classes and is here only as a helper method.
      %
      % SIMPLE(shape) constructs a new simple T-matrix for the given
      % ott.shapes.Shape object.
      %
      % SIMPLE(name, parameters) constructs a new T-matrix for the
      % shape described by the name and parameters.
      %
      % Supported shape names [parameters]:
      %   'sphere'          Spherical (or layered sphere) [ radius ]
      %   'cylinder'        z-axis aligned cylinder [ radius height ]
      %   'ellipsoid'       Ellipsoid [ a b c]
      %   'superellipsoid'  Superellipsoid [ a b c e n ]
      %   'cone-tipped-cylinder'      [ radius height cone_height ]
      %   'cube'            Cube [ width ]
      %   'axisym'          Axis-symetric particle [ rho(:) z(:) ]
      %
      % SIMPLE(..., 'method', method) allows you to choose the
      %   prefered method for T-matrix generation.  This is not
      %   supported for all particle types.  Supported methods are
      %   'ebcm', 'mie' and 'pm'.
      %
      % SIMPLE(..., 'method_tol', tol) specifies the error tolerance
      %   (0, 1] to use for method selection.  Smaller values will
      %   result in a method being choosen that produces higher accuracy.

      % Parse inputs
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('parameters', []);
      p.addParameter('method', '');
      p.addParameter('method_tol', []);

      % Things required for k_medium
      p.addParameter('k_medium', []);
      p.addParameter('wavelength_medium', []);
      p.addParameter('index_medium', []);
      p.addParameter('wavelength0', []);

      p.parse(varargin{:});

      % Parse k_medium
      k_medium = ott.Tmatrix.parser_k_medium(p, 2.0*pi);

      % Get a shape object from the inputs
      if ischar(shape) && ~isempty(p.Results.parameters)
        shape = ott.shapes.Shape.simple(shape, p.Results.parameters);
        varargin = varargin(2:end);
      elseif ~isa(shape, 'ott.shapes.Shape') || ~isempty(p.Results.parameters)
        error('Must input either Shape object or string and parameters');
      end

      % Handle the different particle cases
      if isa(shape, 'ott.shapes.Sphere') ...
          || (isa(shape, 'ott.shapes.Ellipsoid') && shape.isSphere) ...
          || (isa(shape, 'ott.shapes.Superellipsoid') && shape.isSphere)
        if strcmpi(p.Results.method, 'ebcm')
          tmatrix = ott.TmatrixEbcm.simple(shape, varargin{:});
        elseif strcmpi(p.Results.method, 'pm')
          tmatrix = ott.TmatrixPm.simple(shape, varargin{:});
        elseif strcmpi(p.Results.method, '') ...
            || strcmpi(p.Results.method, 'mie')
          tmatrix = ott.TmatrixMie.simple(shape, varargin{:});
        else
          error('ott:Tmatrix:simple:no_method', 'Unsupported method');
        end
      elseif isa(shape, 'ott.shapes.Ellipsoid')
        if strcmp(p.Results.method, 'ebcm')
          tmatrix = ott.TmatrixEbcm.simple(shape, varargin{:});
        elseif strcmp(p.Results.method, '') ...
            || strcmp(p.Results.method, 'pm')
          tmatrix = ott.TmatrixPm.simple(shape, varargin{:});
        else
          error('ott:Tmatrix:simple:no_method', 'Unsupported method');
        end
      elseif isa(shape, 'ott.shapes.Superellipsoid')
        if strcmp(p.Results.method, 'ebcm')
          tmatrix = ott.TmatrixEbcm.simple(shape, varargin{:});
        elseif strcmp(p.Results.method, '') ...
            || strcmp(p.Results.method, 'pm')
          tmatrix = ott.TmatrixPm.simple(shape, varargin{:});
        else
          error('ott:Tmatrix:simple:no_method', 'Unsupported method');
        end
      elseif isa(shape, 'ott.shapes.Cube')
        if strcmp(p.Results.method, 'ebcm')
          tmatrix = ott.TmatrixEbcm.simple(shape, varargin{:});
        elseif strcmp(p.Results.method, '') ...
            || strcmp(p.Results.method, 'pm')
          tmatrix = ott.TmatrixPm.simple(shape, varargin{:});
        else
          error('ott:Tmatrix:simple:no_method', 'Unsupported method');
        end
      elseif isa(shape, 'ott.shapes.Cylinder') ...
          || isa(shape, 'ott.shapes.AxisymLerp')

        method = p.Results.method;
        if strcmp(method, '')

          if isa(shape, 'ott.shapes.Cylinder')
            parameters = [ shape.radius, shape.height ];
          elseif isa(shape, 'ott.shapes.AxisymLerp')
            parameters = [ max(shape.rho), max(shape.z) - min(shape.z) ];
          end

          method = ott.Tmatrix.cylinder_preferred_method(...
              parameters, k_medium, p.Results.method_tol);

          if strcmp(method, 'other')
            warning('ott:Tmatrix:simple:no_cylinder_method', ...
                'No good method found for cylinder, falling back to EBCM');
            method = 'ebcm';
          end
        end

        if strcmp(method, 'ebcm')
          tmatrix = ott.TmatrixEbcm.simple(shape, varargin{:});
        elseif strcmp(method, 'pm')
          tmatrix = ott.TmatrixPm.simple(shape, varargin{:});
        else
          error('ott:Tmatrix:simple:no_method', 'Unsupported method');
        end
      else
        error('ott:Tmatrix:simple:no_shape', 'Unsupported particle shape');
      end
    end

    function method = cylinder_preferred_method(parameters, k, tolerance)
      %CYLINDER_PREFERRED_METHOD selects a method for cylinder calculation
      % Uses the results of Qi et al., 2014 to choose either PM or
      % EBCM to find the T-matrix for a cylinder shaped particle.
      %
      % CYLINDER_PREFERRED_METHOD(parameters, k, tolerance) calculates
      %   the prefered method, either 'pm', 'ebcm' or 'other'.
      %
      %   parameters is a vector with [ particle_radius, height ].
      %
      %   k is the wavenumber in the medium.
      %
      %   tolerance specifies the error tolerance, Qi et al. report
      %   results for tolerances of 0.1 and 0.01.  If tolerance is [],
      %   defaults to 0.01 as the tolerance.

      % EBCM 1% data
      ebcm1 = {};
      ebcm1.x = [73, 169, 198, 228, 261, 391, 586, 718, 718, ...
          657, 523, 457, 262, 73];
      ebcm1.y = [409, 406, 418, 423, 397, 412, 400, 375, 223, ...
          193, 195, 165, 204, 390];
      ebcm1.x = (ebcm1.x - 73) * 2.0 / (718 - 73);
      ebcm1.y = -(ebcm1.y - 438) * 6.0 / (438 - 9);

      % PM 1% data
      pm1 = {};
      pm1.x = [297, 355, 394, 718, 718, 591, 525, 391, 361, 297];
      pm1.y = [943, 933, 946, 894, 868, 846, 874, 864, 913, 913];
      pm1.x = (pm1.x - 73) * 2.0 / (718 - 73);
      pm1.y = -(pm1.y - 985) * 6.0 / (985 - 555);

      % EBCM 10% data
      ebcm10 = {};
      ebcm10.x = [73, 193, 718, 718, 525, 328, 229, 160, 73];
      ebcm10.y = [430, 426, 381, 37, 94, 177, 214, 274, 375];
      ebcm10.x = (ebcm10.x - 73) * 2.0 / (718 - 73);
      ebcm10.y = -(ebcm10.y - 438) * 6.0 / (438 - 9);

      % PM 10% data
      pm10 = {};
      pm10.x = [130, 160, 328, 397, 462, 522, 589, 718, 718, ...
          654, 589, 522, 328, 265, 130];
      pm10.y = [961, 970, 967, 951, 946, 946, 925, 912, 753, ...
          784, 798, 798, 865, 874, 948];
      pm10.x = (pm10.x - 73) * 2.0 / (718 - 73);
      pm10.y = -(pm10.y - 985) * 6.0 / (985 - 555);

      % Conversion factor, paper uses 1064nm illumination
      k = k * 1.064 / 2.0 / pi;
      diameter = 2.0 * parameters(1) * k;
      len = parameters(2) * k;

      if isempty(tolerance)
        tolerance = 0.01;
      end

      if tolerance >= 0.1
        if inpolygon(diameter, len, pm10.x, pm10.y)
            method = 'pm';
        elseif inpolygon(diameter, len, ebcm10.x, ebcm10.y)
            method = 'ebcm';
        else
            method = 'other';
        end
      elseif tolerance >= 0.01
        if inpolygon(diameter, len, pm1.x, pm1.y)
          method = 'pm';
        elseif inpolygon(diameter, len, ebcm1.x, ebcm1.y)
          method = 'ebcm';
        else
          method = 'other';
        end
      else
        method = 'other';
      end
    end

    function [km, kp] = parser_wavenumber(p, default)
      % Parses both k_medium and k_particle, provides n_relative support
      %
      % default is the default value for k_medium;

      % Run the original parsers with default arguments
      km = ott.Tmatrix.parser_k_medium(p, []);
      kp = ott.Tmatrix.parser_k_particle(p, []);

      % If we don't yet have any information, set km from default
      if isempty(km) && isempty(kp)
        km = default;
      end

      % Support for index_relative
      if ~isempty(p.Results.index_relative)
        if isempty(km) && ~isempty(kp)
          km = kp ./ p.Results.index_relative;
        elseif ~isempty(km) && isempty(kp)
          kp = km .* p.Results.index_relative;
        else
          error('index_relative specified but both indices already known');
        end
      elseif isempty(kp)
        error('Unable to determine particle wavenumber from inputs');
      end
    end

    function k_medium = parser_k_medium(p, default)
      %PARSER_K_MEDIUM helper to get k_medium from a parser object

      if ~isempty(p.Results.k_medium)
        k_medium = p.Results.k_medium;
      elseif ~isempty(p.Results.wavelength_medium)
        k_medium = 2.0*pi/p.Results.wavelength_medium;
      elseif ~isempty(p.Results.index_medium)
        if isempty(p.Results.wavelength0)
          error('wavelength0 must be specified to use index_medium');
        end
        k_medium = p.Results.index_medium*2.0*pi/p.Results.wavelength0;
      elseif nargin == 2
        k_medium = default;
      else
        error('Unable to determine k_medium from inputs');
      end
    end

    function k_particle = parser_k_particle(p, default)
      %PARSER_K_PARTICLE helper to get k_particle from a parser object

      if ~isempty(p.Results.k_particle)
        k_particle = p.Results.k_particle;
      elseif ~isempty(p.Results.wavelength_particle)
        k_particle = 2.0*pi/p.Results.wavelength_particle;
      elseif ~isempty(p.Results.index_particle)
        if isempty(p.Results.wavelength0)
          error('wavelength0 must be specified to use index_particle');
        end
        k_particle = p.Results.index_particle ...
            * 2.0*pi/p.Results.wavelength0;
      elseif nargin == 2
        k_particle = default;
      else
        error('Unable to determine k_particle from inputs');
      end
    end
  end

 methods (Abstract)
 end

 methods (Access=protected)
  function tmatrix = Tmatrix(data, type)
    %TMATRIX construct a new T-matrix object
    %
    % TMATRIX() leaves the data uninitialised.
    %
    % TMATRIX(data) initializes the data with the matrix data.

    if nargin >= 1
      tmatrix.data = data;
      tmatrix.type = type;
    end
  end
 end

  methods
    function nmax = get.Nmax(tmatrix)
      %get.Nmax calculate Nmax from the current T-matrix data
      nmax1 = ott.utils.combined_index(size(tmatrix.data, 1)/2);
      nmax2 = ott.utils.combined_index(size(tmatrix.data, 2)/2);

      % Support non-square T-matrices
      nmax = [nmax1 nmax2];
    end

    function tmatrix = set.Nmax(tmatrix, nmax)
      %set.Nmax resizes the T-matrix
      tmatrix = tmatrix.set_Nmax(nmax);
    end

    function tmatrix = set_Nmax(tmatrix, nmax, varargin)
      % SET_NMAX resize the T-matrix, with additional options
      %
      % SET_NMAX(nmax) sets the T-matrix Nmax.  nmax should be a
      % scarar or 2 element vector with row/column Nmax.
      %
      % SET_NMAX(..., 'tolerance', tol) use tol as the warning error
      % level tolerance for resizing the beam.
      %
      % SET_NMAX(..., 'powerloss', mode) action to take if a power
      % loss is detected.  Can be 'ignore', 'warn' or 'error'.

      p = inputParser;
      p.addParameter('tolerance', 1.0e-6);
      p.addParameter('powerloss', 'warn');
      p.parse(varargin{:});

      % Convert the input to row/column sizes
      if length(nmax) == 2
        nmax1 = nmax(1);
        nmax2 = nmax(2);
      else
        nmax1 = nmax(1);
        nmax2 = nmax(1);
      end

      % Check if we need to do anything
      if all([nmax1, nmax2] == tmatrix.Nmax)
        return;
      end

      total_orders1 = ott.utils.combined_index(nmax1, nmax1);
      total_orders2 = ott.utils.combined_index(nmax2, nmax2);

      midpoint1 = size(tmatrix.data, 1)/2;
      midpoint2 = size(tmatrix.data, 2)/2;

      % The current resizing method only works for scattered fields
      old_type = tmatrix.type;
      if total_orders1 > midpoint1 || total_orders2 > midpoint2 ...
          && strcmpi(old_type, 'total')
        tmatrix.type = 'scattered';
      end

      % Split T-matrix into quadrants
      A11 = tmatrix.data(1:midpoint1, 1:midpoint2);
      A12 = tmatrix.data(1:midpoint1, (midpoint2+1):end);
      A21 = tmatrix.data((midpoint1+1):end, 1:midpoint2);
      A22 = tmatrix.data((midpoint1+1):end, (midpoint2+1):end);

      % Resize rows
      if total_orders1 > midpoint1

        [row_index,col_index,a] = find(A11);
        A11 = sparse(row_index,col_index,a,total_orders1,midpoint2);

        [row_index,col_index,a] = find(A12);
        A12 = sparse(row_index,col_index,a,total_orders1,midpoint2);

        [row_index,col_index,a] = find(A21);
        A21 = sparse(row_index,col_index,a,total_orders1,midpoint2);

        [row_index,col_index,a] = find(A22);
        A22 = sparse(row_index,col_index,a,total_orders1,midpoint2);

      elseif total_orders1 < midpoint1

        A11 = A11(1:total_orders1, :);
        A12 = A12(1:total_orders1, :);
        A21 = A21(1:total_orders1, :);
        A22 = A22(1:total_orders1, :);

      end

      % Resize cols
      if total_orders2 > midpoint2

        [row_index,col_index,a] = find(A11);
        A11 = sparse(row_index,col_index,a,total_orders1,total_orders2);

        [row_index,col_index,a] = find(A12);
        A12 = sparse(row_index,col_index,a,total_orders1,total_orders2);

        [row_index,col_index,a] = find(A21);
        A21 = sparse(row_index,col_index,a,total_orders1,total_orders2);

        [row_index,col_index,a] = find(A22);
        A22 = sparse(row_index,col_index,a,total_orders1,total_orders2);

      elseif total_orders2 < midpoint2

        A11 = A11(:, 1:total_orders2);
        A12 = A12(:, 1:total_orders2);
        A21 = A21(:, 1:total_orders2);
        A22 = A22(:, 1:total_orders2);

      end

      if total_orders1 < midpoint1 || total_orders2 < midpoint2
        magA = full(sum(sum(abs(tmatrix.data).^2)));
      end

      % Recombined T-matrix from quadrants
      tmatrix.data = [ A11 A12; A21 A22 ];

      if total_orders1 < midpoint1 || total_orders2 < midpoint2
        magB = full(sum(sum(abs(tmatrix.data).^2)));
        apparent_error = abs( magA - magB )/magA;

        if apparent_error > p.Results.tolerance
          if strcmpi(p.Results.powerloss, 'warn')
            ott.warning('ott:Tmatrix:setNmax:truncation', ...
                ['Apparent error of ' num2str(apparent_error)]);
          elseif strcmpi(p.Results.powerloss, 'error')
            error('ott:Tmatrix:setNmax:truncation', ...
                ['Apparent error of ' num2str(apparent_error)]);
          elseif strcmpi(p.Results.powerloss, 'ignore')
            % Nothing to do
          else
            error('Unrecognized option for powerloss');
          end
        end
      end

      % If we were originally total field, convert back
      tmatrix.type = old_type;
    end

    function type = get.type(tmatrix)
      % Get the T-matrix type
      type = tmatrix.type_;
    end

    function tmatrix = set.type(tmatrix, type)
      % Set the T-matrix type, converting if needed
      tmatrix = tmatrix.set_type(type);
    end

    function tmatrix = set_type(tmatrix, type, varargin)
      % SET_TYPE set T-matrix type with additional options

      p = inputParser;
      p.addParameter('convert', true);
      p.parse(varargin{:});

      % Check the type is valid
      if ~strcmpi(type, 'total') && ~strcmpi(type, 'internal') ...
          && ~strcmpi(type, 'scattered')
        error('Invalid T-matrix type');
      end

      % Do type conversions
      if p.Results.convert && ~isempty(tmatrix.type) ...
          && ~strcmpi(tmatrix.type, type)
        if strcmpi(tmatrix.type, 'scattered') && strcmpi(type, 'total')
          tmatrix.data = 2.0*tmatrix.data + speye(size(tmatrix.data));
        elseif strcmpi(tmatrix.type, 'total') && strcmpi(type, 'scattered')
          tmatrix.data = 0.5*(tmatrix.data - speye(size(tmatrix.data)));
        else
          error('No known conversion');
        end
      end

      % Set the type
      tmatrix.type_ = type;
    end

    function tmatrix = total(tmatrix)
      % TOTAL convert T-matrix to total
      tmatrix.type = 'total';
    end

    function tmatrix = scattered(tmatrix)
      % SCATTERED convert T-matrix to scattered
      tmatrix.type = 'scattered';
    end

    function sbeam = mtimes(tmatrix,ibeam)
      %MTIMES provide T-matrix multiplication overload
      sbeam = ibeam.scatter(tmatrix);
    end
  end
end
