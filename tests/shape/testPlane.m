function tests = testPlane
  tests = functiontests(localfunctions);
end

function setupOnce(~)
  addpath('../../');
end

function testConstructor(testCase)

  normal = [0;0;1];
  offset = 0.0;

  shape = ott.shape.Plane(normal, 'offset', offset);

  testCase.verifyEqual(shape.normal, normal, 'normal');
  testCase.verifyEqual(shape.offset, offset, 'normal');
  testCase.verifyEqual(shape.xySymmetry, false, 'xysym');
  testCase.verifyEqual(shape.zRotSymmetry, 0, 'zsym');
  testCase.verifyEqual(shape.starShaped, false, 'star');
  testCase.verifyEqual(shape.maxRadius, Inf, 'maxR');
  testCase.verifyEqual(shape.volume, Inf, 'volume');
  testCase.verifyEqual(shape.boundingBox, [-Inf, Inf; -Inf, Inf; -Inf, 0], 'bb');
  testCase.verifyEqual(shape.normalsXyz([0;0;0]), normal, 'normalXyz');
  
  % Scale
  Sshape = shape * 2;
  testCase.verifyEqual(Sshape, shape, 'scale');

end

function testCasts(testCase)

  normal = [0;0;1];
  shape = ott.shape.Plane(normal, 'offset', 0);
  shape2 = ott.shape.Plane(normal, 'offset', 1);
  
  slab = ott.shape.Slab([shape, shape2]);
  testCase.verifyInstanceOf(slab, 'ott.shape.Slab');
  
  strata = ott.shape.Strata([shape, shape2]);
  testCase.verifyInstanceOf(strata, 'ott.shape.Strata');
  
end

function testInsideXyz(testCase)

  plane = ott.shape.Plane();

  xyz = [0, 0; 0, 0; 1, -1];
  b = plane.insideXyz(xyz);
  testCase.verifyEqual(b, [true, false]);

end

function testSurf(testCase)

  normal = rand(3, 1);
  offset = 0.0;

  plane = ott.shape.Plane(normal, 'offset', offset);

  h = figure();
  testCase.addTeardown(@close, h);

  p = plane.surf('scale', 2.0);
  testCase.verifyClass(p, 'matlab.graphics.primitive.Patch');
  
  testCase.verifyError(@() plane.surfPoints(), ...
    'ott:shape:mixin:NoSurfPoints:surf_points');

end

function testIntersect(testCase)

  normal = [0;0;1];
  offset = 0.0;

  plane = ott.shape.Plane(normal, 'offset', offset);

  x0 = [0;0;-1];
  x1 = x0 + [1;0;0];
  locs = plane.intersect(x0, x1);
  testCase.verifyEqual(locs, nan(3, 1), 'parallel ray');

  x0 = [0;0;-1];
  x1 = x0 + [0;0;1];
  locs = plane.intersect(x0, x1);
  testCase.verifyEqual(locs, [0;0;0], 'nice ray');

  x0 = [0;0;-1];
  x1 = x0 + [0;0;-1];
  locs = plane.intersect(x0, x1);
  testCase.verifyEqual(locs, nan(3, 1), 'negative ray');

end

