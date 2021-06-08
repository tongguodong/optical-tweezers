classdef NewParticleBase < ott.ui.support.AppTopLevel ...
    & ott.ui.support.AppProducer
% Base class for particle generation applications
%
% Properties
%   - Data
%
% Abstract methods
%   - generateCode
%   - generateParticle

% Copyright 2021 IST Austria, Written by Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file.
  
  properties (Access=protected)
    MainGrid              matlab.ui.container.GridLayout
    ExtraGrid             matlab.ui.container.GridLayout
  end
  
  methods (Access=protected)
    function setDefaultValues(app)
      app.VariableName.Value = '';
      app.UpdateButton.Level = 0;
      app.UpdateButton.clearErrors();
    end
    
    function createMainComponents(app)
      
      % Generate grid
      app.MainGrid = uigridlayout(app.UIFigure);
      app.MainGrid.ColumnWidth = {'1x', '1x'};
      app.MainGrid.RowHeight = {32, '1x', 32};
      app.MainGrid.ColumnSpacing = 20;
      
      % Variable name field
      app.VariableName = ott.ui.support.OutputVariableEntry(app.MainGrid);
      app.VariableName.Layout.Row = 1;
      app.VariableName.Layout.Column = 1;
      
      % Grid for other components
      app.ExtraGrid = uigridlayout(app.MainGrid);
      app.ExtraGrid.Padding = [10, 0, 10, 0];
      app.ExtraGrid.ColumnWidth = {'1x', '1x'};
      app.ExtraGrid.ColumnSpacing = 20;
      app.ExtraGrid.Layout.Row = 2;
      app.ExtraGrid.Layout.Column = [1,2];
      
      % Generate button
      app.UpdateButton = ott.ui.support.UpdateWithProgress(app.MainGrid);
      app.UpdateButton.Layout.Row = 3;
      app.UpdateButton.Layout.Column = 2;
    end
  end
end