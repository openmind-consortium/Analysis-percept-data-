timeline_extract=json_to_mat();

%Will only run if LFPTrendLogs exist. This file is to extract LFPTrendLogs,
%long-term out of clinic data. 
%Next steps: 
    %improve flow if unilateral
    %Improve graphics on Figures, labeling
    %Save figures produced to the created directory

hem_label="";
%Will plot unilateral twice ('Right' and 'Left') if data is unilateral
if ~isfield(timeline_extract.DiagnosticData.LFPTrendLogs,'HemisphereLocationDef_Right')
    timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right=timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left;
    fprintf('Only Left! ');
    hem_label="Left";
elseif ~isfield(timeline_extract.DiagnosticData.LFPTrendLogs,'HemisphereLocationDef_Left')
    timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left=timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right;
    fprintf('Only Right! ');
    hem_label="Right";
else
    hem_label="";
end  
left_timeline=timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left
right_timeline=timeline_extract.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right


runs = fieldnames(left_timeline);

LFP=[];
STIM=[];
DT=[];
%Plot for whole time period (ie over multiple days, up to 60 days)
for c = 1:length(runs)
               ldata = left_timeline.(runs{c});
               rdata = right_timeline.(runs{c});
               LFP=[LFP;[[rdata(:).LFP];[ldata(:).LFP]]'];
               STIM=[STIM;[[rdata(:).AmplitudeInMilliAmps];[ldata(:).AmplitudeInMilliAmps]]'];
               DT = [DT datetime({ldata(:).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''')];
end
figure

subplot(2,1,1)
yyaxis left
scatter(DT,LFP(:,1),14,[1 0 0])
ylabel('LFP')
ylim([0 150])
hold on
yyaxis right
plot(DT,STIM(:,2))
ylabel('Stim (mA)')
hold off

    if ~(hem_label=="")
        title(hem_label)
    else
        title('Left')
    end
xlabel('Date/Time')



subplot(2,1,2)
yyaxis left
scatter(DT,LFP(:,2),14,[1 0 1])
ylabel('LFP')
ylim([0 5000])
hold on
yyaxis right
plot(DT,STIM(:,2))
ylabel('Stim (mA)')
hold off

    if ~(hem_label=="")
        title(hem_label)
    else
        title('Right')
    end

xlabel('Date/Time')

%Plot each day
LFP_day=[];
STIM_day=[];
DT_day=[];
for c = 1:length(runs)
        figure
               ldata_day = left_timeline.(runs{c});
               rdata_day = right_timeline.(runs{c});
               LFP_day=[[[rdata_day(:).LFP];[ldata_day(:).LFP]]'];
               STIM_day=[[[rdata_day(:).AmplitudeInMilliAmps];[ldata_day(:).AmplitudeInMilliAmps]]'];
               DT_day = [datetime({ldata_day(:).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''')];
        
                subplot(2,1,1)
                
                yyaxis left
                scatter(DT_day,LFP_day(:,1),14,[1 0 0])
                ylabel('LFP')
                ylim([0 150])
                hold on
                yyaxis right
                plot(DT_day,STIM_day(:,2))
                ylabel('Stim (mA)')
                hold off
                    if ~(hem_label=="")
                        title(hem_label)
                    else
                        title('Left')
                    end
             
                xlabel('Date/Time')
             

                subplot(2,1,2)
                yyaxis left
                scatter(DT_day,LFP_day(:,2),14,[1 0 1])
                ylabel('LFP')
                ylim([0 5000])
                hold on
                yyaxis right
                plot(DT_day,STIM_day(:,2))
                ylabel('Stim (mA)')
                hold off
              
                if ~(hem_label=="")
                   title(hem_label)
                else
                   title('Right')
                end
                
                
                xlabel('Date/Time')
                
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
