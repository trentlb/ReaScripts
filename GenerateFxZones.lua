local resourcePath = reaper.GetResourcePath() .. '/CSI/Zones/xtouch4/_FX_Zones';
local faderCount = 8;

function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end


local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end




local numTracks = reaper.GetNumTracks();
for trackIdx=0, numTracks do
  
  
  local selectedTrack= reaper.GetTrack(0, trackIdx);
  if selectedTrack then
    local _, track_name = reaper.GetSetMediaTrackInfo_String(selectedTrack, "P_NAME", "", false)
    --reaper.ShowMessageBox( 'Hi', track_name, 0);
    local FXChain = reaper.CF_GetTrackFXChain( selectedTrack );
    
    local fx_cnt = reaper.TrackFX_GetCount(selectedTrack);
    --reaper.ShowMessageBox('hi', fx_cnt, 0);
    --local fx_chain = FXChain.Get(0)
    
    
    --reaper.ShowMessageBox('Hi', resourcePath, 0);
    
    for i = 1, fx_cnt do
      local _, name = reaper.TrackFX_GetFXName(selectedTrack, i, "");
      
      
      local trimmedName = string.gsub(name, "%s+", "");
      if trimmedName~=nil and trimmedName~='' then 
        --local fx_chunk = FXChain.GetFXChunk(fx_chain, i)
        --reaper.ShowMessageBox( 'Hi', name, 0);
        
        
        --search for fx name in files.  
        --if found, don't do anything.
        --if not found create a file
        
        local isFound = false;
        
        local files = scandir(resourcePath);
        --reaper.ShowMessageBox('Hi', #files,0);
        
        for j=1, #files do
          if ends_with(files[j], ".zon")  then
    --        reaper.ShowMessageBox('Hi', files[j],0);
      
    --        getmatches((files[j])
            
            
            for line in io.lines(resourcePath .. '/' .. files[j]) do
                --local a,b=line:match("^"..name)
                local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
                --reaper.ShowMessageBox('name: ', name,0);
                --reaper.ShowMessageBox('trimmed: ', trimmed,0);
                --break;
                
                if trimmed~=nil and trimmed~='' and string.find(trimmed,name,0,true) then
                    --reaper.ShowMessageBox('nio','found '..name..' in '..trimmed,0);
                    isFound = true;
                    break;
                end
            end
            
          end
        
        end
        
        if not isFound then
          --write a file!
          --reaper.ShowMessageBox('writing file for: ', name,0);
          
          local filenameNoExt = resourcePath .. '/' .. name:gsub( "%W", "" );
          
          --get params
          --count params
          local paramCount = reaper.TrackFX_GetNumParams( selectedTrack, i );
          
          
          --if there are more than faderCount params, prepare to create subzones.
          local totalZones = math.ceil(paramCount / faderCount);
          --reaper.ShowMessageBox('totalZones for '..name..': ', totalZones,0);
          
          
          local zoneArr = {};
          for z = 0, totalZones do
            --local filenameNoPath = string.sub(filenameNoExt,(filenameNoExt:reverse()):find("%/")+1,#filenameNoExt);
            local filenameNoPath = filenameNoExt:match("^.+/(.+)$");
            zoneArr[z] = "\""..name .. '-' .. z .. "\"";
          end
  
   
          local currentZone = 0;
          local faderIndex = 1;
          local filename, file;
          local isFileOpen = false;
          for k=0, paramCount do
          
            --are we at the beginning of a file?
            if (k) % faderCount==0 then
              faderIndex = 1;
              --yep
              if k==0 then
                filename = filenameNoExt .. ".zon"; --not including number for first file
              else
                filename = filenameNoExt .."-"..currentZone..".zon";
              end
              file = io.open (filename, "w");
              isFileOpen = true;
              io.output(file)
              
              local shortName = string.sub(name,string.find(name,':')+2,#name);
              local nameToPrint = name;
              if currentZone > 0 then 
                nameToPrint = name .. '-' .. currentZone;
              end
              
              if currentZone == 0 then
                --include alias
                io.write("Zone \"" .. nameToPrint .. "\" \"" .. shortName .. '\"\n');
              else
                --no alias
                io.write("Zone \"" .. nameToPrint .. "\"\n");
              end
              
              if k==0 then --beginning of first file, write subzones
                io.write("     SelectedTrackNavigator" .. '\n');
                io.write('         SubZones\n');
                for w=0, (#zoneArr-1) do
                  if w~=currentZone then
                    io.write('             '..zoneArr[w]..'\n');
                  end
                end
                io.write('         SubZonesEnd\n');
              end
              
              --now write navigation
              local back=currentZone-1;
              local forward=currentZone +1;
              
              --io.write("/\n");
              if back == -1 then
                --last page
                io.write("     ChannelLeft    GoZone \""..name..'-'..(totalZones-1).."\"\n");
              elseif back == 0 then
                --first page (no number)
                io.write("     ChannelLeft    GoZone \""..name.."\"\n");
              else
                io.write("     ChannelLeft    GoZone \""..name..'-'..back.."\"\n");
              end
              
              if forward>(totalZones-1) then
                --back to zone 1
                io.write("     ChannelRight    GoZone \""..name.."\"\n");
              else
                io.write("     ChannelRight    GoZone \""..name..'-'..forward.."\"\n");
              end
              --io.write("/\n");
              
            end
          
            local retval, buf = reaper.TrackFX_GetParamName( selectedTrack, i, k );
            
            --local retval, minval, maxval = reaper.TrackFX_GetParam( selectedTrack, i, k )
            local trimmedParm = string.gsub(buf, "%s+", "");
            if trimmedParm~=nil and trimmedParm~='' then 
              --reaper.ShowMessageBox('pn: ', buf, 0);
              
              
              local kPlusOne = k+1;
              io.write("     Fader"..(faderIndex).." FXParam "..(k).." \""..trimmedParm.."\"".."\n");
              --Shift+Rotary1 FXParam 2 "Q-Band 1"
              io.write("     DisplayUpper"..faderIndex.."          FXParamNameDisplay "..k.." \""..trimmedParm.."\"".."\n");
              io.write("     DisplayLower"..faderIndex.."        FXParamValueDisplay "..k.."\n");
              faderIndex = faderIndex + 1;
              
            end
          
          
            --are we at the end of a file?
            if ((k+1) % faderCount==0) or ((k+1)==paramCount) then
              --write file end
              if isFileOpen then 
                io.write("ZoneEnd" .. '\n');
                 
                -- io.write();
                io.close();
                isFileOpen = false;
              end
              
              currentZone = currentZone + 1;
            end
          
          end -- param for loop
          
          --io.write("     ChannelLeft              TrackBank     \"-1\"\n");
          --io.write("     ChannelRight             TrackBank     \"1\"\n");
          --io.write("     BankLeft                 TrackBank     \"-8\"\n");
          --io.write("     BankRight                TrackBank     \"8\"\n");
          
          
        end --isNotFound
        
      end --trimmedName
      
      --local bp1, bp2, bp3 = fx_chunk:match("BYPASS (%d) (%d) (%d)\n")
      --if bp1 == "1" then bp1 = "0" elseif bp1 == "0" then bp1 = "1" end
      --local new_state = "BYPASS ".. bp1 .. " " .. bp2 .. " " .. bp3 .. "\n"
      --fx_chunk = fx_chunk:gsub("BYPASS %d %d %d\n", new_state)
      --FXChain.SetFXChunk(fx_chain, fx_chunk, i)
      
    --local use_src_track_chunk = false
    --FXChain.Set(track, fx_chain, use_src_track_chunk)
    
    
    end
  end
end --loop over tracks
