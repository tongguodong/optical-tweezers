function tests = testPlaneWave
  tests = functiontests(localfunctions);
end

function setupOnce(testCase)
  addpath('../../');
end

function testConstructor(testCase)

  direction = [0; 0; 1];
  polarisation = [1; 0; 0];
  beam = ott.beam.PlaneWave('direction', direction, ...
    'polarisation', polarisation);
  
  testCase.verifyEqual(beam.direction, direction, 'dir');
  testCase.verifyEqual(beam.polarisation, polarisation, 'pol');
end

function testConstructorIndexMedium(testCase)

  index_medium = 1.33;
  beam = ott.beam.PlaneWave('index', index_medium);
  testCase.verifyEqual(beam.medium.index, index_medium, 'index');
  testCase.verifyEqual(beam.medium.speed0, 1.0, 'speed0');
  testCase.verifyEqual(beam.wavelength0, 1.0, 'lambda0');

end

function testConstructorArray(testCase)

  direction = [0, 0; 0, 0; 1, -1];
  polarisation = [1; 0; 0];
  beam = ott.beam.PlaneWave('direction', direction, ...
    'polarisation', polarisation);
  
  testCase.verifyEqual(beam.direction, direction, 'dir');
  testCase.verifyEqual(beam.polarisation, repmat(polarisation, 1, 2), 'pol');
end

function testFromFarfield(testCase)
  beam = ott.beam.paraxial.Gaussian(1.0);
  beam = ott.beam.PlaneWave.FromFarfield(beam);
end

function testFromNearfield(testCase)
  beam = ott.beam.paraxial.Gaussian(1.0);
  beam = ott.beam.PlaneWave.FromNearfield(beam);
end

function testFromParaxial(testCase)
  beam = ott.beam.paraxial.Gaussian(1.0);
  beam = ott.beam.PlaneWave.FromParaxial(beam);
end

function testVisualise(tsetCase)

  direction = [0, 0; 0, 0; 1, -1];
  polarisation = [1; 0; 0];
  beam = ott.beam.PlaneWave('direction', direction, ...
    'polarisation', polarisation);
  
  h = figure();
  beam.visualise();
  close(h);
  
end

function testFarfield(testCase)

%   gbeam = ott.optics.beam.GaussianParaxial(1.0);
%   beam = ott.optics.beam.PlaneWave.FromFarfield(gbeam);

  direction = [0; 0; 1];
  polarisation = [1; 0; 0];
  beam = ott.beam.PlaneWave('direction', direction, ...
    'polarisation', polarisation);
  
  h = figure();
  beam.visualiseFarfieldSphere();
  close(h);

  h = figure();
  beam.visualiseFarfieldSphere('method', 'delta');
  close(h);
end

function testForce(testCase)

  P1 = ott.beam.PlaneWave('direction', [0;0;1]);
  P2 = ott.beam.PlaneWave('direction', [0;0;-1]);
  
  f = P1.force(P2);
  testCase.verifyEqual(f, [0;0;2], 'reflected wave');
  
  P2.field = 0.0;
  f = P1.force(P2);
  testCase.verifyEqual(f, [0;0;1], 'reflected wave');

  P1 = ott.beam.PlaneWave('direction', [0;0;1], 'polarisation', [0;1;0]);
  P2 = ott.beam.PlaneWave('direction', [1;0;0], 'polarisation', [0;1;0]);
  
  f = P1.force(P2);
  testCase.verifyEqual(f, [-1;0;1.0], 'perpendicular wave');
  
  f2 = P2.force(P1);
  testCase.verifyEqual(f2, -f, 'oposite sign');
  
end

function testForceBeamArray(testCase)

  P1 = ott.beam.PlaneWave('direction', [0;0;1]);
  P2 = ott.beam.PlaneWave('direction', [0;0;-1]);
  
  beam1 = [P1, P1, P1];
  beam2 = [P2, P2, P2];
  
  beam1.array_type = 'array';
  beam2.array_type = 'array';
  f = beam1.force(beam2);
  testCase.verifyEqual(f, [0;0;2].*[1,1,1], 'array');
  
  beam1.array_type = 'coherent';
  beam2.array_type = 'coherent';
  f = beam1.force(beam2);
  testCase.verifyEqual(f, [0;0;2].*numel(beam1).^2, 'coherent');
  
  beam1.array_type = 'incoherent';
  beam2.array_type = 'incoherent';
  f = beam1.force(beam2);
  testCase.verifyEqual(f, [0;0;6], 'incoherent');
  
end

function testLogicalSelection(testCase)

  P1 = ott.beam.PlaneWave('direction', [0;0;1], 'polarisation', [0;1;0]);
  P2 = ott.beam.PlaneWave('direction', [1;0;0], 'polarisation', [0;1;0]);
  
  array = [P1, P2];
  empty = ott.beam.PlaneWave.empty();
  
  testCase.verifyEqual(array([true, false]), P1, 'P1');
  testCase.verifyEqual(array([true, true]), array, 'P1');
  testCase.verifyEqual(array([false, false]), empty, 'P1');

end