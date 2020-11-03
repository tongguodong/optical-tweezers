classdef AxisymStarShape < ott.shape.mixin.StarShape ...
    & ott.shape.mixin.AxisymShape
% Define additional constrains for star shaped axis-symmetric particles.
% Inherits from :class:`StarShape` and :class:`AxisymShape`.
%
% Methods
%   - normalsRzInternal
%   - normalsRtInternal
%   - normalsRtpInternal
%   - normalsXyzInternal
%   - insideRzInternal
%   - insideRtInternal
%   - insideRtpInternal
%   - insideXyzInternal
%
% Abstract methods
%   - normalsTInternal
%
% Supported casts
%   - ott.shape.AxisymInterp

% Copyright 2020 Isaac Lenton
% This file is part of the optical tweezers toolbox.
% See LICENSE.md for information about using/distributing this file.

  methods (Abstract)
    normalsTInternal(obj)
  end

  methods
    function shape = ott.shape.AxisymInterp(shape, varargin)
      % Cast shape to a AxisymInterp shape
      %
      % Usage
      %   shape = ott.shape.AxisymInterp(shape, ...)
      %
      % Optional named arguments
      %   - resolution (numeric) -- Number of faces in the theta direction.
      %     Default: ``20``.
      %
      % Additional named parameters are passed to constructor.

      p = inputParser;
      p.addParameter('resolution', 20);
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      unmatched = ott.utils.unmatchedArgs(p);

      % Evaluate surface locations
      theta = linspace(0, pi, p.Results.resolution + 1);
      R = shape.starRadii(theta, 0*theta);

      % Convert to cylindrical coordinates
      points = [R.*sin(theta); R.*cos(theta)];

      % Construct AxisymInterp
      shape = ott.shape.AxisymInterp(points, ...
          'position', shape.position, 'rotation', shape.rotation, ...
          unmatched{:});
    end
  end

  methods (Hidden)
    function nxyz = normalsXyzInternal(varargin)
      nxyz = normalsXyzInternal@ott.shape.mixin.AxisymShape(varargin{:});
    end

    % normalsRtp declared in AxisymShape

    function nxyz = normalsRzInternal(shape, rz, varargin)
      % Convert to angular coordinates
      nxyz = shape.normalsTInternal(atan2(rz(2, :), rz(1, :)), varargin{:});
    end

    function nxyz = normalsRtInternal(shape, rt, varargin)
      % Discard radial coordinate
      nxyz = shape.normalsTInternal(rt(2, :), varargin{:});
    end

    function b = insideRzInternal(shape, rz, varargin)
      b = vecnorm(rz) <= shape.starRadii(atan2(rz(2, :), rz(1, :)), 0);
    end

    function b = insideRtInternal(shape, rt, varargin)
      b = rt(1, :) <= shape.starRadii(rt(2, :), 0);
    end

    function b = insideRtpInternal(varargin)
      b = insideRtpInternal@ott.shape.mixin.StarShape(varargin{:});
    end
    function b = insideXyzInternal(varargin)
      b = insideXyzInternal@ott.shape.mixin.AxisymShape(varargin{:});
    end
  end
end