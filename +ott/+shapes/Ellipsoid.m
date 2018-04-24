classdef Ellipsoid < ott.shapes.StarShape & ott.shapes.AxisymShape
%Ellipsoid a simple ellipsoid shape
%
% properties:
%   a         % x-axis scaling
%   b         % y-axis scaling
%   c         % z-axis scaling
%
% This file is part of the optical tweezers toolbox.
% See LICENSE.md for information about using/distributing this file.

  properties
    a
    b
    c
  end

  methods
    function shape = Ellipsoid(a, b, c)
      % ELLIPSOID construct a new ellipsoid
      %
      % ELLIPSOID(a, b, c) or ELLIPSOID([a, b, c]) specifies the
      % scaling in the x, y and z directions.

      shape = shape@ott.shapes.StarShape();

      if nargin == 1
        shape.a = a(1);
        shape.b = a(2);
        shape.c = a(3);
      else
        shape.a = a;
        shape.b = b;
        shape.c = c;
      end

    end

    function r = get_maxRadius(shape)
      % Calculate the maximum particle radius
      r = max([shape.a, shape.b, shape.c]);
    end

    function p = get_perimiter(shape)
      % Calculate the perimiter of the object

      % Check that the particle is axisymmetric
      axisym = shape.axialSymmetry();
      if axisym(3) ~= 0
        p = NaN;
        return;
      end

      a = max(shape.a, shape.b);
      b = min(shape.a, shape.b);

      % Calculate the perimiter using recursion
      e = sqrt(shape.a.^2 + shape.b.^2)/a;
      nmax = 100;
      p = 0.0;
      pold = 0.0;
      tol = 1.0e-6;
      for ii = 1:nmax
        p = p + factorial(2*ii).^2 / (2^ii * factorial(ii)).^4 ...
            * e^(2*ii) / (2*ii - 1);
        if abs(p - pold)/abs(pold) < tol
          break;
        end
        pold = p;
      end

      % Add the correction term
      p = 2*a*pi*(1.0 - p);
    end

    function r = radii(shape, theta, phi)
      % RADII returns the radius for each requested point

      theta = theta(:);
      phi = phi(:);
      [theta,phi] = ott.utils.matchsize(theta,phi);

      r = 1 ./ sqrt( (cos(phi).*sin(theta)/shape.a).^2 + ...
          (sin(phi).*sin(theta)/shape.b).^2 + (cos(theta)/shape.c).^2 );
    end

    function n = normals(shape, theta, phi)
      % NORMALS calcualtes the normals for each requested point

      theta = theta(:);
      phi = phi(:);
      [theta,phi] = ott.utils.matchsize(theta,phi);

      % r = 1/sqrt( cos(phi)^2 sin(theta)^2 / a^2 +
      %     sin(phi)^2 sin(theta)^2 / b2 + cos(theta)^2 / c^2 )
      % dr/dtheta = -r^3 ( cos(phi)^2 / a^2 + sin(phi)^2 / b^2
      %             - 1/c^2 ) sin(theta) cos(theta)
      % dr/dphi = -r^3 sin(phi) cos(phi) (1/b^2 - 1/a^2) sin(theta)^2
      % sigma = rhat + thetahat r^2 sin(theta) cos(theta) *
      %     ( cos(phi)^2/a^2 + sin(phi)^2/b^2 - 1/c^2 )
      %    + phihat r^2 sin(theta) sin(phi) cos(phi) (1/b^2 - 1//a^2)

      r = shape.radii(theta, phi);
      sigma_r = ones(size(r));
      sigma_theta = r.^2 .* sin(theta) .* cos(theta) .* ...
          ( (cos(phi)/shape.a).^2 + (sin(phi)/shape.b).^2 - 1/shape.c^2 );
      sigma_phi = r.^2 .* sin(theta) .* sin(phi) .* cos(phi) .* ...
          (1/shape.b^2 - 1/shape.a^2);
      sigma_mag = sqrt( sigma_r.^2 + sigma_theta.^2 + sigma_phi.^2 );
      n = [ sigma_r./sigma_mag sigma_theta./sigma_mag ...
          sigma_phi./sigma_mag ];
    end

    function varargout = axialSymmetry(shape)
      % Return the axial symmetry for the particle

      if shape.a == shape.b; ab = 0; else; ab = 2; end
      if shape.a == shape.c; ac = 0; else; ac = 2; end
      if shape.b == shape.c; bc = 0; else; bc = 2; end

      if nargout == 1
        varargout{1} = [ bc, ac, ab ];
      else
        varargout{1} = bc;
        varargout{2} = ac;
        varargout{3} = ab;
      end
    end

    function varargout = mirrorSymmetry(shape)
      % Return the mirror symmetry for the particle

      if nargout == 1
        varargout{1} = [ true, true, true ];
      else
        varargout{1} = true;
        varargout{2} = true;
        varargout{3} = true;
      end
    end
  end
end
