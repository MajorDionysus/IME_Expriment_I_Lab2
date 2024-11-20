classdef ECG_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        FilterButton            matlab.ui.control.StateButton
        GoodHRLabel             matlab.ui.control.Label
        SamplingEditField       matlab.ui.control.EditField
        SamplingEditFieldLabel  matlab.ui.control.Label
        TimeEditField           matlab.ui.control.EditField
        TimeEditFieldLabel      matlab.ui.control.Label
        YourHREditField         matlab.ui.control.EditField
        YourHREditFieldLabel    matlab.ui.control.Label
        Alarm                   matlab.ui.control.Lamp
        StartButton             matlab.ui.control.Button
        ECGmeasurementLabel     matlab.ui.control.Label
        frequency               matlab.ui.control.UIAxes
        time                    matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        v; % voltage
        t; % time
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            % 初始化一些东西
            app.Alarm.Color=[0,1,0];
            app.GoodHRLabel.Text='Good HR';
            app.YourHREditField.Value='0';
            fs=app.SamplingEditField.Value;
            fs=str2double(fs);
            time_set=app.TimeEditField.Value;
            time_set=str2double(time_set);
            devices = daqlist;
            s = daq('ni');
            addinput(s,'Dev#', 0, 'Voltage');
            s.Rate = fs;
            acqtime = time_set;
            data = read(s, seconds(acqtime));
            votage=data{:,:};
            tx = data.Time;
            votage=votage(1)-votage(2);

            % test
            % load("Signal_Data.mat");
            % votage=LII;
            % tx=0:1/fs:(length(votage)-1)/fs;

            % load('Signal_Data.mat','v','t','fs');
            % votage=v;
            % tx=t;
            % votage=votage(:,1)-votage(:,2);

            votage = votage-mean(votage);
            N = length(votage);
            n = 0:N-1;  
            df = n*fs/N;
            FT = fft(votage);
            app.v=votage;
            app.t=tx;

            ax=app.time;
            plot(ax,app.t,real(app.v));
            
            % save file
            % filename = sprintf('data_%s.mat', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
            % save(filename, "votage", "tx");

            % FFT
            bx=app.frequency;
            plot(bx,df,abs(FT));
            xlim(bx,[0,100])

        end

        % Value changed function: YourHREditField
        function YourHREditFieldValueChanged(app, event)

            % 只是测试ALarm可以忽略

            value = app.YourHREditField.Value;
            value = str2double(value);
            if value>119
                app.GoodHRLabel.Text="Your HR is too hign";
                app.Alarm.Color=[1,0,0];
                for i=1:10
                    pause(0.2);
                    sound(sin(2*pi*25*(1:4000)/100));
                    if mod(i,2)==1
                    app.Alarm.Color=[0.9,0.9,0.9];
                    else
                        app.Alarm.Color=[1,0,0];
                    end
                end
            end

            if value>59&&value<120
                app.GoodHRLabel.Text="Good HR";
                app.Alarm.Color=[0,1,0];
                load handel
                sound(y,Fs)
            end

            if value<60&&value>0
                app.GoodHRLabel.Text="Your HR is too low";
                app.Alarm.Color=[1,0,0];
                for i=1:10
                    pause(0.2);
                    sound(sin(2*pi*25*(1:4000)/100));
                    if mod(i,2)==1
                    app.Alarm.Color=[0.9,0.9,0.9];
                    else
                        app.Alarm.Color=[1,0,0];
                    end
                end
            end
        end

        % Value changed function: FilterButton
        function FilterButtonValueChanged(app, event)
            fs=app.SamplingEditField.Value;
            fs=str2double(fs);
            votage = app.v;
            N = length(votage);
            n = 0:N-1;  
            df = n*fs/N;
            FT = fft(votage);

            if fs>200
                h=ones(1,length(FT));
                h(df>(df(end)-52)&df<(df(end)-48))=0.01;
                h(df>48&df<52)=0.01;
                FT=FT.*h';
            end
            app.v=ifft(FT);

            [pks,locs] = findpeaks(real(app.v), app.t, 'MinPeakProminence',0.8);
            hr = round(60 / mean(diff(locs)));
            sd = hr - round(60 / (mean(diff(locs)) + std(diff(locs))));
            app.YourHREditField.Value=sprintf('%d±%d',hr,sd);

            ax=app.time;
            plot(ax,app.t,real(app.v));
            ax.NextPlot = 'add';
            scatter(ax,locs,pks);
            ax.NextPlot= 'replacechildren';

            bx=app.frequency;
            plot(bx,df,abs(FT));
            xlim(bx,[0,100])

            % Alarm
            value = hr;
            if value>119
                app.GoodHRLabel.Text="Your HR is too hign";
                app.Alarm.Color=[1,0,0];
                for i=1:10
                    pause(0.2);
                    sound(sin(2*pi*25*(1:4000)/100));
                    if mod(i,2)==1
                    app.Alarm.Color=[0.9,0.9,0.9];
                    else
                        app.Alarm.Color=[1,0,0];
                    end
                end
            end

            if value>59&&value<120
                app.GoodHRLabel.Text="Good HR";
                app.Alarm.Color=[0,1,0];
                load handel
                sound(y(1:round(end/4)),Fs)
            end

            if value<60&&value>0
                app.GoodHRLabel.Text="Your HR is too low";
                app.Alarm.Color=[1,0,0];
                for i=1:10
                    pause(0.2);
                    sound(sin(2*pi*25*(1:4000)/100));
                    if mod(i,2)==1
                    app.Alarm.Color=[0.9,0.9,0.9];
                    else
                        app.Alarm.Color=[1,0,0];
                    end
                end
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.902 0.902 0.902];
            app.UIFigure.Position = [100 100 751 560];
            app.UIFigure.Name = 'MATLAB App';

            % Create time
            app.time = uiaxes(app.UIFigure);
            title(app.time, 'Time domain')
            xlabel(app.time, 't/s')
            ylabel(app.time, 'Voltage/v')
            zlabel(app.time, 'Z')
            app.time.Position = [34 225 326 232];

            % Create frequency
            app.frequency = uiaxes(app.UIFigure);
            title(app.frequency, 'Frequency domain')
            xlabel(app.frequency, 'f/Hz')
            ylabel(app.frequency, 'Magnititude')
            zlabel(app.frequency, 'Z')
            app.frequency.Position = [398 232 326 225];

            % Create ECGmeasurementLabel
            app.ECGmeasurementLabel = uilabel(app.UIFigure);
            app.ECGmeasurementLabel.FontSize = 36;
            app.ECGmeasurementLabel.Position = [217 490 319 47];
            app.ECGmeasurementLabel.Text = 'ECG-measurement';

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.FontSize = 18;
            app.StartButton.Position = [110 62 100 33];
            app.StartButton.Text = 'Start';

            % Create Alarm
            app.Alarm = uilamp(app.UIFigure);
            app.Alarm.Position = [547 20 75 75];

            % Create YourHREditFieldLabel
            app.YourHREditFieldLabel = uilabel(app.UIFigure);
            app.YourHREditFieldLabel.HorizontalAlignment = 'right';
            app.YourHREditFieldLabel.FontSize = 18;
            app.YourHREditFieldLabel.Position = [455 152 77 23];
            app.YourHREditFieldLabel.Text = 'Your HR:';

            % Create YourHREditField
            app.YourHREditField = uieditfield(app.UIFigure, 'text');
            app.YourHREditField.ValueChangedFcn = createCallbackFcn(app, @YourHREditFieldValueChanged, true);
            app.YourHREditField.FontSize = 18;
            app.YourHREditField.Position = [547 148 100 27];

            % Create TimeEditFieldLabel
            app.TimeEditFieldLabel = uilabel(app.UIFigure);
            app.TimeEditFieldLabel.HorizontalAlignment = 'right';
            app.TimeEditFieldLabel.FontSize = 18;
            app.TimeEditFieldLabel.Position = [161 152 49 23];
            app.TimeEditFieldLabel.Text = 'Time:';

            % Create TimeEditField
            app.TimeEditField = uieditfield(app.UIFigure, 'text');
            app.TimeEditField.HorizontalAlignment = 'center';
            app.TimeEditField.FontSize = 18;
            app.TimeEditField.Position = [225 148 100 27];
            app.TimeEditField.Value = '10';

            % Create SamplingEditFieldLabel
            app.SamplingEditFieldLabel = uilabel(app.UIFigure);
            app.SamplingEditFieldLabel.HorizontalAlignment = 'right';
            app.SamplingEditFieldLabel.FontSize = 18;
            app.SamplingEditFieldLabel.Position = [125 114 85 23];
            app.SamplingEditFieldLabel.Text = 'Sampling:';

            % Create SamplingEditField
            app.SamplingEditField = uieditfield(app.UIFigure, 'text');
            app.SamplingEditField.HorizontalAlignment = 'center';
            app.SamplingEditField.FontSize = 18;
            app.SamplingEditField.Position = [225 110 100 27];
            app.SamplingEditField.Value = '1000';

            % Create GoodHRLabel
            app.GoodHRLabel = uilabel(app.UIFigure);
            app.GoodHRLabel.HorizontalAlignment = 'center';
            app.GoodHRLabel.FontSize = 18;
            app.GoodHRLabel.Position = [391 111 205 23];
            app.GoodHRLabel.Text = 'Good HR';

            % Create FilterButton
            app.FilterButton = uibutton(app.UIFigure, 'state');
            app.FilterButton.ValueChangedFcn = createCallbackFcn(app, @FilterButtonValueChanged, true);
            app.FilterButton.Text = 'Filter';
            app.FilterButton.FontSize = 18;
            app.FilterButton.Position = [225 63 100 30];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ECG_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
