%write a SeaBASS file - top of the file is the header text with specific
%lines required by NASA; bottom of the file is the datafile from the
%project. This m-file generates the data file first, but you can work in
%any order.
%NASA SeaBASS file will end with *sb as its file extension
%Krista Longnecker; Woods Hole Oceanographic Institution
%8 April 2025; 16 April 2025
%KL 5/21/2025 add time and some unit details after email from NASA
clear all 
close all

%load up the data and make a table
wDir = 'C:\Users\klongnecker\Documents\Dropbox\Current projects\Longnecker_NASA_IDS\RawData\Bioavailability';
load([wDir,filesep,'PB_bioavailability_allYears.2025.05.21.mat'])
allYears = sortrows(allYears,'samplePoint_DT');
allYears.date = yyyymmdd(allYears.samplePoint_DT);
allYears.incubation_hours = allYears.incubation_Days*24;
%SeaBASS will require a cruise, and requires one data file per cruise...for
%this project that will be three data files
byYear = [2019 2022 2023];
nameCruise = {'PBcarbonUnderIce19','PBcarbonUnderIce22','PBcarbonUnderIce23'};
cruiseDates = {'20190523','20190524';'20220510','20220523';'20230329','20230522'}; 

%what is the list of variables to be exported?
vList = {'Station','Bottle','date','Time','Lat','Lon',...
    'WaterDepth_M','salinity_psu','filterType',...
    'initialDOC','initialDOC_SD','BDOC','BDOC_SE','RDOC','RDOC_SE','PO4_uM','NO2_uM','NplusN','incubation_hours'};

%predefine variables with zeros (in this dataset, these are empty and *not* a
%data with a value of zero). These will become -999 in the loop below
tZ = {'WaterDepth_M','salinity_psu','initialDOC_SD','BDOC','BDOC_SE','RDOC_SE'};

for a = 1:3 %use a loop to setup the three data files, one file per iteration
    k = find(allYears.Year==byYear(a));
    allYears.cruise(k) = {nameCruise(a)};
   
    forExport = allYears(k,vList); %new, small table with one year of data
    clear k 

    %sort the table - first on date and then on time
    forExport = sortrows(forExport,{'date','Time'});
    
    %using a MATLAB table makes finding the zeros a pain
    for aa = 1:length(tZ)
        k = find(forExport{:,tZ(aa)}==0);
        forExport{k,tZ(aa)} =-999;
        clear k
    end
    clear aa
    
    %sadly salinity, BDOC, and water_depth, and nutrients have both 0 and NaN values,
    %change those to -999 here
    i = isnan(forExport.salinity_psu);
    forExport.salinity_psu(i) = -999;
    clear i
    
    i = isnan(forExport.BDOC);
    forExport.BDOC(i) = -999;
    forExport.BDOC_SE(i) = -999;
    forExport.RDOC(i) = -999;
    forExport.RDOC_SE(i) = -999;
    clear i
    
    i = isnan(forExport.WaterDepth_M);
    forExport.WaterDepth_M(i) = -999;
    clear i
    
    i = isnan(forExport.PO4_uM);
    forExport.PO4_uM(i) = -999;
    forExport.NO2_uM(i) = -999;
    forExport.NplusN(i) = -999;
    
    
    %Now is when the table is handy - have MATLAB make a CSV file with the
    %data that will be read back into MATLAB later to make the sb file.
    %%careful - you need WriteVariableNames as false, WriteRowNames gets
    %%ignored for some reason.
    writetable(forExport,'temp.csv','WriteVariableNames',false);
    
    %Now move on to making the header for the SeaBASS file
    %each row in the header begins with a '/'; write the header row-by-row and
    %then put in the data as comma-delimited data
    useNewline = newline(); %cannot use '\n' or \'r' as those will cause error in FCHECK
    headerFile = 'header.txt';
    fid = fopen(headerFile,'wt');
    fprintf(fid,'%s','/','begin_header');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','received=2025xxxx');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','identifier_product_doi=xx');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','investigators=Krista_Longnecker');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','affiliations=Woods_Hole_Oceanographic_Institution');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','contact=klongnecker@whoi.edu');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','experiment=PBseaice');
    fprintf(fid,useNewline);
    %one file per cruise, generate this name in the loop
    cName = strcat('Cruise=',nameCruise(a));
    fprintf(fid,'%s','/',cName{1});
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','water_depth=NA');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','measurement_depth=1');
    fprintf(fid,useNewline);
    %one file per cruise, generate this name in the loop
    cfName = strcat('PBseaice_',nameCruise(a),'_DOC_RDOC_BDOC_','20250521','.R1.sb');
    fprintf(fid,'%s','/',strcat('data_file_name=',cfName{1}));
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','documents=SeaBASS_Submission_Checklist_DOC_EXPERIMENT_PB_seaice_CRUISES_PBcarbonUnderIce_19_22_23.docx,DOC_BDOC_RDOC_methods.docx'); 
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','calibration_files=no_cal_files');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','data_type=bottle');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','instrument_model=TOCL');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','instrument_manufacturer=Shimadzu');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','missing=-999');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','delimiter=comma');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/',strcat('start_date=',cruiseDates{a,1}));
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/',strcat('end_date=',cruiseDates{a,2}));
    fprintf(fid,useNewline);
    % %change start_time and end_time to be based on the times of sample collection
    % fprintf(fid,'%s','/','start_time=00:00:00[GMT]');
    % fprintf(fid,useNewline);
    % fprintf(fid,'%s','/','end_time=00:00:00[GMT]');
    % fprintf(fid,useNewline);
    cName = strcat('start_time=',char(forExport.Time(1)),'[GMT]'); 
    fprintf(fid,'%s','/',cName); clear cName
    fprintf(fid,useNewline);
    cName = strcat('end_time=',char(forExport.Time(end)),'[GMT]'); 
    fprintf(fid,'%s','/',cName); clear cName
    fprintf(fid,useNewline);

    fprintf(fid,'%s','/','north_latitude=70.512[DEG]');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','south_latitude=70.4002[DEG]');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','east_longitude=-147.9912[DEG]');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','west_longitude=-148.7768[DEG]');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','fields=station,bottle,date,time,lat,lon,water_depth,water_column_salinity,filter_type,DOC_L,DOC_L_sd,BDOC_L,BDOC_L_se,RDOC_L,RDOC_L_se,PO4,NO2,NO2_NO3,incubation_duration');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','units=none,none,YYYYMMDD,hh:mm:ss,degrees,degrees,m,none,none,umol/l,umol/l,umol/l,umol/l,umol/l,umol/l,mmol/m^3,mmol/m^3,mmol/m^3,hh');
    fprintf(fid,useNewline);
    fprintf(fid,'%s','/','end_header');
    fprintf(fid,useNewline);
    fclose(fid);
        
    %%now that the header is done, combine the two text files...this is
    %%actually done outside of MATLAB as a system command
    makeString = strcat('copy /b header.txt+temp.csv ',{' '},cfName{1}); %don't forget the space: {' '}
    system(makeString{1}); %need the {1} to get this out of the cell array
    clear cName cfName makeString
end
clear a


