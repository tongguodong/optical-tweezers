classdef Simple < ott.ui.beam.AppBase

% Copyright 2021 IST Austria, Written by Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file.

  properties (Constant)
    cnameText = 'Simple';

    nameText = 'Simple Beam';

    aboutText = ['Generate a simple beam.'];
    
    helpText = {ott.ui.beam.Simple.aboutText, ...
      ''};
  end
  
end