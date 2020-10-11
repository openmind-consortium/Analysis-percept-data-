%Extracts patient events
%'LfpFrequencySnapshotEvents' must exist

patient_events=json_to_mat();
events=patient_events.DiagnosticData.LfpFrequencySnapshotEvents
name_event=[];
event_date=[];
%Plot each event
for c = 1:length(events)
  event=events(c);
  event_date_input=event.DateTime 
  event_date = datetime(event_date_input,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''');
  date_string = datestr(event_date);
  name_event= event.EventName;
            hem_label=[];
        if ~isfield(event.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
            event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left;
            fprintf('Only Left! ');
            hem_label="Left";
        elseif ~isfield(event.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
            event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right;
            fprintf('Only Right! ');
            hem_label="Right";
        else
            hem_label=[];
        end  
left_freq=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.Frequency;
left_FFTB=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;

right_freq=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.Frequency;
right_FFTB=event.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;


figure
    subplot(2,1,1)
    plot(left_freq,left_FFTB)
    xlabel('Frequency (Hz)')
    ylabel('FFTB (μVp)')
    name_event_s1= convertCharsToStrings(name_event);
    
    %Make label right for both if unilateral to right
    hem_l=strings;
    if ~isfield(event.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
        hem_l="Right Hemisphere";
    else
        hem_l="Left Hemisphere";
    end
    title(hem_l)
    
    subplot(2,1,2)
    plot(right_freq,right_FFTB)
    xlabel('Frequency (Hz)')
    ylabel('FFTB (μVp)')
    name_event_s2= convertCharsToStrings(name_event);
    %Make label right for both if unilateral to right
    hem_r=strings;
    if ~isfield(event.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
        hem_r="Left Hemisphere";
    else
        hem_r="Right Hemisphere";
    end
    title(hem_r)
    name_event_date = append(name_event,' ',date_string)
    sgtitle(name_event_date);
    
    
end
%Get Patient Events
%This function calls json file and extracts proper data
function [js] = json_to_mat()
%Work in progress to simply load information from Percept json file for data analysis 

%Convert json to structure in Matlab
[filename, pathname] = uigetfile('*.json');
json = fileread([pathname,filename]);
js = jsondecode(json);

%Allow user to set subject ID for file naming
prompt= 'State subject ID: ';
js.subject = input(prompt,'s');
% 
infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation','LeadConfiguration','Stimulation','Groups','Impedance','PatientEvents','EventSummary','DiagnosticData'};


%Display location of Stimulator (sanity check if file is loaded)
disp(js.DeviceInformation.Final.NeurostimulatorLocation)

%Format dates and other information (add all relevant data here)
    js.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' '));
    js.SessionDate = datetime(strrep(js.SessionDate(1:end-1),'T',' '));
    js.Diagnosis = strsplit(js.PatientInformation.Final.Diagnosis,'.');js.Diagnosis=js.Diagnosis{2};
    js.OriginalFile = filename;
    js.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1),'T','_'),':','-');
    js.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
    js.LeadLocation = strsplit(js.LeadConfiguration.Final(1).LeadLocation,'.');js.LeadLocation=js.LeadLocation{2};
   
%Session labeled 
js.session = ['ses-' char(datetime(js.SessionDate,'format','yyyyMMddhhmmss')) num2str(js.BatteryPercentage)];



%Make file in current folder with user-prompted subject ID

    if ~exist(fullfile(js.subject,js.session,'ieeg'),'dir')
        mkdir(fullfile(js.subject,js.session,'ieeg'));
    end
    
    js.fpath = fullfile(js.subject,js.session,'ieeg');
    js.fname = [js.subject '_' js.session];
    js.chan = ['LFP_' js.LeadLocation];
    js.d0 = datetime(js.SessionDate(1));
    
end
