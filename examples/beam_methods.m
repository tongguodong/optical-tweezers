% Example demonstrating the different beams in the toolbox
%
% This file generates images demonstrating the beams included in the
% toolbox, for a full list of these beams and example output of this
% script, see the Beams section of the documentation.
%
% Most beams can be created using the +abstract beam classes.  These
% classes invoke the implementation classes for field visualisations.
% The implementation classes use various approximations and can produce
% different results.  Additional control over the generated beam can
% be achieved by either explicitly casting the abstract beams or
% directly invoking the beam implementation classes.

% Copyright 2020 Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file.

% Add the toolbox to the path
addpath('../');

%% Gaussian beams

figure();

% Create an abstract Gaussian beam
paraxial_waist = 0.5;
abstract_beam = ott.beam.abstract.Gaussian(paraxial_waist, ...
    'polarisation', [1, 0]);

% The default abstract visualisation method is GaussianDavis5
% Alternatively, we could explicitly pick GaussianDavis5 using
% ott.beam.GaussianDavis5(abstract_beam).visualise()
subplot(1, 4, 1);
abstract_beam.visualise('range', [1, 1]);
title('5-th order Davis');

% Paraxial beam approximation produces slightly different fields
subplot(1, 4, 2);
paraxial = ott.beam.paraxial.Paraxial(abstract_beam);
paraxial.visualise('range', [1, 1]);
title('Paraxial');

% There are two kinds of VSWF representations of a Gaussian beam,
% they differ by the paraxial-to-farfield mapping used for point-matching.
% The default is 'sintheta' mapping, which produces results similar to
% many high-NA microscope objectives
bsc_sintheta = ott.beam.vswf.Bsc(abstract_beam);
subplot(1, 4, 3);
bsc_sintheta.visualise('range', [1, 1]);
title('VSWF: sintheta');

% The other mapping is 'tantheta', which should produce similar results
% for lower focussing (larger paraxial beam waist).
bsc_tantheta = ott.beam.vswf.Bsc(abstract_beam, 'mapping', 'tantheta');
subplot(1, 4, 4);
bsc_tantheta.visualise('range', [1, 1]);
title('VSWF: tantheta');

%% Laguerre-Gaussian beams

figure();

% LG beam with azimuthal mode (lmode = -5) and radial mode (rmode = 3)
paraxial_waist = 2;
abstract_beam = ott.beam.abstract.LaguerreGaussian(paraxial_waist, ...
    'lmode', -5, 'pmode', 3, 'polarisation', [1, 1i]);

% Default visualisation method is Paraxial
subplot(1, 2, 1);
abstract_beam.visualise('range', 2*[1, 1]);

% Can also construct a VSWF representation
subplot(1, 2, 2);
ott.beam.vswf.Bsc(abstract_beam).visualise('range', 2*[1, 1]);

%% Hermite-Gaussian beams

figure();

% HG beam with azimuthal mode (mmode = -5) and radial mode (nmode = 3)
paraxial_waist = 0.5;
abstract_beam = ott.beam.abstract.HermiteGaussian(paraxial_waist, ...
    'mmode', -5, 'nmode', 3, 'polarisation', [1, 0]);

% Default visualisation method is Paraxial
subplot(1, 2, 1);
abstract_beam.visualise();

% Can also construct a VSWF representation
subplot(1, 2, 2);
ott.beam.vswf.Bsc(abstract_beam).visualise();

%% Ince-Gaussian beam

figure();

% Construct an Ince-Gaussian beam
paraxial_waist = 0.5;
abstract_beam = ott.beam.abstract.InceGaussian(paraxial_waist, ...
    'pmode', 5, 'parity', 'even', 'polarisation', [1, 1i]);

% Default visualisation method is VSWF
abstract_beam.visualise();

%% Plane wave beams

figure();

% A single plane wave can be constructed using the abstract class
subplot(1, 4, 1);
abstract_beam = ott.beam.abstract.PlaneWave();
abstract_beam.visualise('field', 'Re(Ex)');

% For arrays it is better to invoke the PlaneWave class directly
directions = randn(3, 5);
plane_waves = ott.beam.PlaneWave('direction', directions);

% Arrays of plane waves can be coherent or incoherent
subplot(1, 4, 2);
plane_waves.array_type = 'coherent';
plane_waves.visualise();

subplot(1, 4, 3);
plane_waves.array_type = 'incoherent';
plane_waves.visualise();

% Some beam approximations are only valid in a certain range, this is
% particularly true for PlaneWaves with VSWF representation, as demonstrated
% by the following visualisation
subplot(1, 4, 4);
beam = ott.beam.vswf.Bsc(abstract_beam, 'suggested_Nmax', 10);
beam.visualise('range', [3, 3]);

%% Geometric ray beams
% Geometric rays are similar to Plane waves except their visualisation
% method draws rays instead of fields and their e/h-field methods default
% to a plane wave with a transverse intensity fall-off term.

figure();

% As with plane waves, the abstract class can be used to construct a
% single ray or for many rays it is better to call the Ray class directly
directions = randn(3, 5);
origin = zeros(3, 5);
rays = ott.beam.Ray('direction', directions, 'origin', origins);

% Default visualisation method draws rays
% Coherent/incoherent property has no effect for this visualisation
subplot(1, 2, 1);
rays.visualise();

% A field can be specified, this effectively draws the rays as
% plane-waves with a transverse intensity fall-off
% Coherent/incoherent property changes the visualisation
subplot(1, 2, 2);
rays.visualise('field', 'Re(Ex)');

%% Bessel beam

figure();

theta = pi/4;
abstract_beam = ott.beam.abstract.Bessel(theta);

abstract_beam.visualise();

%% Annular beam

figure();

theta = [pi/8, pi/4];
abstract_beam = ott.beam.abstract.Annular(theta);

abstract_beam.visualise();

%% Dipole beam

% Describes the radiation field of a single dipole
% beam.abstract.Dipole creates a single dipole, or many dipoles can be
% created with beam.Dipole
polarizations = randn(3*5);
positions = randn(3, 5);
dipoles = ott.beam.Dipole('dipole_xyz', positions, ...
    'polarizations', polarizations);

% The default visualisation sets the color range so that dipoles
% in the visualisation plane don't over-saturate the image.  This causes
% dipoles to appear as patches of constant intensity.
figure();
dipoles.visualise();

%% Top-Hat beams
% The toolbox includes two top-hat beams: a collimated top-hat beam
% implemented using NearfieldMasked3d, and a focussed top-hat
% implemented using ParaxialMasked.

figure();

beam = ott.beam.abstract.TopHat('radius', 1.0);
subplot(1, 2, 1);
beam.visualise('axis', 'y');
title('Collimated Top-hat');

beam = ott.beam.abstract.FocussedTopHat('radius', 1.0, ...
    'paraxial_waist', 0.5);
subplot(1, 2, 1);
beam.visualise('axis', 'y');
title('Focussed Top-hat');

%% Masked beams
% The abstract Masked classes can be used to construct different combinations
% of beams with masked profiles.  The following example shows how to
% represent a Annular mask of a Gaussian beam.

figure();

% Paraxial beam to be masked
gaussian = ott.beam.abstract.Gaussian('waist', 0.5);
subplot(1, 4, 1);
gaussian.visualiseFarfield();

% Annular mask (and visualisation using sin-theta mapping
mask = @(theta, phi) theta < pi/4 & theta > pi/8;
subplot(1, 4, 2);
[X, Y] = meshgrid(linspace(-1, 1), linspace(-1, 1));
T = asin(sqrt(X.^2 + Y.^2));
P = atan2(Y, X);
pcolor(X, Y, mask(T, P));

% Combined beam + mask
beam = ott.beam.abstract.FarfieldMasked('mask', mask, ...
    'beam', gaussian, 'mapping', 'sintheta');

% Far-field visualisation simply shows the mask applied to the beam
subplot(1, 4, 3);
beam.visualiseFarfield();
title('Far-field');

% Near-field visualisation converts the beam to a VSWF beam first
subplot(1, 4, 4);
beam.visualise();
title('Near-field');

%% Point-matching and plane-wave basis beams
% Beams can also be created by point-matching a near-field or far-field
% image of the beam intensity or by constructing a plane-wave basis
% representation of the beam.  This section includes three different
% methods for simulating the near-field of a paraxial far-field beam:
%
%   - Fast Fourier transform
%   - VSWF Far-field point-matching
%   - VSWF plane wave basis

% Generate a paraxial field
[X, Y] = meshgrid(linspace(-1, 1, 20), linspace(-1, 1, 20));
Ex = X.^2 + Y.^2;
Ey = zeros(size(Ex));
E = cat(3, Ex, Ey);

% Construct a abstract representation of this field
% This uses interpolation over the paraxial far-field.
paraxial_beam = ott.beam.abstract.InterpParaxial.FromGrid(X, Y, E);

figure();

% Visualise the far-field
subplot(1, 4, 1);
paraxial_beam.visualiseFarfield();

% Visualise the near-field
% This implicitly casts the beam to a paraxial.Fft for calculating fields
% around the focal plane.  Note: Additional control over the cast can be
% achieved by using an explicit cast instead of an implicit cast.
subplot(1, 4, 2);
paraxial_beam.visualise();

% Alternatively, we can also cast the beam to a VSWF point-matched beam
vswf_beam = ott.beam.vswf.Pointmatch(paraxial_beam);
subplot(1, 4, 3);
vswf_beam.visualise();

% Or a VSWF plane wave basis beam
% This creates one plane wave for each non-zero paraxial field point
vswf_beam = ott.beam.vswf.PlaneBasis(paraxial_beam);
subplot(1, 4, 4);
vswf_beam.visualise();

