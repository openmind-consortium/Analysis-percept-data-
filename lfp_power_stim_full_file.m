%Gives LFP Power (Unitless) and Stim Amplitude (mA) Over Time
%Allow user to select file
%File must have 'BrainSenseLFP', which is from in-clinic streaming.
clear;

lfp_data=json_to_mat()

LFP_data_ticks=[];
right_LFP=[];
right_stim=[];
left_LFP=[];
left_stim=[];

time_start=datetime(lfp_data.BrainSenseLfp(1).FirstPacketDateTime,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
time_start_s = datestr(time_start);

for i=1:length(lfp_data.BrainSenseLfp)
    data_temp=lfp_data.BrainSenseLfp(i);
    sample_rate=data_temp.SampleRateInHz;
    channel=data_temp.Channel;
    %time_start=datetime(data_temp.FirstPacketDateTime,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
    %time_start_s = datestr(time_start);
       %Extract Time points in ticks
        LFP_data_ticks=[LFP_data_ticks,data_temp.LfpData.TicksInMs];
        %Extract right Side
        right_LFP_struct=[data_temp.LfpData.Right];
        right_LFP=[ right_LFP,right_LFP_struct.LFP];
        %Extract right stimulation (mA)
        right_stim_struct=[data_temp.LfpData.Right];
        right_stim=[right_stim,right_LFP_struct.mA];
       %Extract left Side
        left_LFP_struct=[data_temp.LfpData.Left];
        left_LFP=[left_LFP,left_LFP_struct.LFP];
       %Extract left stimulation (mA)
        left_stim_struct=[data_temp.LfpData.Left];
        left_stim=[left_stim,left_LFP_struct.mA];
        %Plot
       
        
       
 end
    
 subplot(2,1,1)
        
        xlabel('Ticks')
        
        %Plot LFP over time
        yyaxis left
        plot(LFP_data_ticks,right_LFP,LFP_data_ticks,right_stim)
        ylabel('LFP Power (unitless)')
        %Stimulation axis
       
        yyaxis right
        plot(LFP_data_ticks,right_stim)
        ylabel('Stimulation (mA)')
        ylim([0 4])
        
        title('Right Hemisphere')
        
        subplot(2,1,2)
        
        xlabel('Ticks (mS)')
        
        %Plot LFP over time
        yyaxis left
        plot(LFP_data_ticks,left_LFP,LFP_data_ticks,left_stim)
        ylabel('LFP Power (unitless)')
        
        %Stimulation axis
        yyaxis right
        plot(LFP_data_ticks,left_stim)
        ylabel('Stimulation (mA)')
        ylim([0 4])
        title('Left Hemisphere')
        %Name overall subplot
        name_event_date = append("Stimulation Test",' ',time_start_s)
        sgtitle(time_start_s);
    
    
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
