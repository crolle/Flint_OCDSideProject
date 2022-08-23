%%OCD Flint Side Project Behavioral Analyses
%%Cammie Rolle
%%8.21.2022
clear all;clc;%close all


%%Parameters
dataDir='C:\Users\Cammie\Desktop\FlintOutputs\';
scriptDir='C:/Users/crolle/Desktop/NeuroPace_QC/NeuroPace_QCScripts/Scripts/';
addpath(genpath(scriptDir),'-END');
subFolders=dir([dataDir '*.txt']);
saveDir=[dataDir '/Outputs/'];mkdir(saveDir);
dataAll=[];

for ss=1:length(subFolders)
    
    
    %% Subject Information Setup
    fileName=subFolders(ss).name;nameind=findstr(fileName,'_');subID=fileName(1:nameind(1)-1);
    
    %% Task import
    clc
    disp(['Running OCD Behavioral QC on Subject : ' subID]);
    clearvars -except subID ss dataDir subFolders saveDir fileName dataAll
    
    %%Load in Data
    delimiter = '\t';
    formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';
    startRow = 10;
    fid = fopen([dataDir '/' fileName],'r');
    dataArray = textscan(fid, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    fclose(fid);
    C = [dataArray{1:8}];
    dataTmpAll=[];
    header={'SubID','TimeStamp','BlockNumber','BlockType','Trial','StarTtime','ImageName','RT','Response'};
    dataTmp=[repmat(subID,length(C),1) C];dataTmp=dataTmp(2:end,:);
    dataAll=[dataTmp;dataAll];
    
    disp(['Done with ' subID])
end

%% Plot histogram
responses=str2double(dataAll(:,9));
categories=dataAll(:,4);
catUnique=unique(categories);
ID_beh=dataAll(:,1);for ss=1:length(ID_beh);ID_beh(ss)=ID_beh{ss}(4:end);end;ID_beh=str2double(ID_beh);

%Plot
clear corrData
close all
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    catind=find(strcmp(categories, catUnique{cc}));
    catData=responses(catind) ;
    hist(catData);
    title(catUnique{cc});xlabel('Rating');ylabel('Frequency')
    %Save data for correlations
    corrData(cc).data={catData};corrData(cc).cat=catUnique(cc);corrData(cc).ID=ID_beh(catind);
end
saveas(gcf,[saveDir 'ResponseHistxCategory.png']);close

%% OCI Correlations

surveyFile=[dataDir 'QUALTRICS_OUTPUTS.xlsx'];
surveyData=readtable(surveyFile);

%Change string to num
responseU={'Not at All';'A Little';'Moderate';'A Lot';'Extremely'};
dataTmp=surveyData(:,14:end);
clear data_OCI dataTmp2
for tt=1:size(dataTmp,2)
    dataTmp2=table2cell(dataTmp(:,tt));
    for uu=1:length(responseU)
    uInd=find(strcmp(dataTmp2,responseU{uu}));
    dataTmp2(uInd)={num2str(uu)};
    data_OCI(:,tt)=dataTmp2;
    end
end    
data_OCI=str2double(data_OCI);

%Subscore 12 and 18
data_OCI(:,19)=data_OCI(:,12)+data_OCI(:,18);

%Correlate - Get Ready
ID_qual=str2double(table2cell(surveyData(:,1)));
clear behData responseData
for ss=1:length(ID_qual)
   %correlate per cat
   for cc=1:length(catUnique)
   subind=find(corrData(cc).ID==ID_qual(ss));
   if isempty(subind);
       responseData=NaN;
   else
   responseData=corrData(cc).data{1,1}(subind,:);
   end
   responseData_mean(ss,cc)=nanmean(responseData);
   responseData_std(ss,cc)=nanstd(responseData);
   responseData_median(ss,cc)=nanmedian(responseData);
   end
end


%Plot Sub Averages
close all
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    hist(responseData_mean(:,cc));
    title(catUnique{cc});xlabel(' Rating - Average');ylabel('Frequency')
end
saveas(gcf,[saveDir 'ResponseHistxCategoryxSubAve.png']);close

close all
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    hist(responseData_median(:,cc));
    title(catUnique{cc});xlabel(' Rating - Median');ylabel('Frequency')
end
saveas(gcf,[saveDir 'ResponseHistxCategoryxSubMed.png']);close

close all
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    hist(responseData_std(:,cc));
    title(catUnique{cc});xlabel(' Rating - Variance');ylabel('Frequency')
end
saveas(gcf,[saveDir 'ResponseHistxCategoryxSubStd.png']);close

%Correlate - Run
barTitles={'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '10';...
    '11'; '12'; '13'; '14'; '15'; '16'; '17'; '18'; '12+18'};
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    [r,p]=corr(responseData_mean(:,cc),data_OCI,'rows','complete');
    bar(r);xticks(1:1:length(barTitles));xticklabels(barTitles);
    xlabel('OCI Question');ylabel('Rho Co Coeff'); title([catUnique{cc} ' Mean']);
    hold on
    for pp=1:length(p)
        if p(pp)<.05
            ax=gca;text(pp,ax.YLim(2)-.05,sprintf('%.2f',p(pp)));hold on
        end
    end
end
saveas(gcf,[saveDir 'CorrValues_ResponseMean.png']);close

figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    [r,p]=corr(responseData_median(:,cc),data_OCI,'rows','complete');
    bar(r);xticks(1:1:length(barTitles));xticklabels(barTitles);
    xlabel('OCI Question');ylabel('Rho Co Coeff'); title([catUnique{cc} ' Median']);
    hold on
    for pp=1:length(p)
        if p(pp)<.05
            ax=gca;text(pp,ax.YLim(2)-.05,sprintf('%.2f',p(pp)));hold on
        end
    end
end
saveas(gcf,[saveDir 'CorrValues_ResponseMedian.png']);close
    
figure('units','normalized','outerposition',[0 0 1 1]);
for cc=1:length(catUnique)
    subplot(3,2,cc)
    [r,p]=corr(responseData_std(:,cc),data_OCI,'rows','complete');
    bar(r);xticks(1:1:length(barTitles));xticklabels(barTitles);
    xlabel('OCI Question');ylabel('Rho Co Coeff'); title([catUnique{cc} ' Variance']);
    hold on
    for pp=1:length(p)
        if p(pp)<.05
            ax=gca;text(pp,ax.YLim(2)-.05,sprintf('%.2f',p(pp)));hold on
        end
    end
end
saveas(gcf,[saveDir 'CorrValues_ResponseSTD.png']);close