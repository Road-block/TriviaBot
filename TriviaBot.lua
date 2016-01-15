--[[
--
-- TriviaBot Version 1.2
-- Written by Guri of Trollbane
-- Based on work created by Psy on Frostwolf
--
--]]

-- Global Variables

-- Declared colour codes for console messages
local RED     = "|cffff0000";
local MAGENTA = "|cffff00ff";
local WHITE   = "|cffffffff";

TRIVIA_ENABLED = false;
TRIVIA_LOADED = false;

TRIVIA_QUESTION_TIMEOUT = 45;  --45 Seconds to Answer Correctly
TRIVIA_QUESTION_TIMEWARN = 25;  --20 Second warning.

TRIVIA_VERSION = "1.2" -- Version number

NEW_TRIVIA_CHANNEL = nil; -- For changing channels

TRIVIA_ACTIVE_QUESTION = 0; -- The currently active question
TRIVIA_QUESTION_ORDER = {}; -- An array to store in which order the questions will be asked
TRIVIA_SCORE_REPORT = 5; -- How often the score is reported
TRIVIA_QUESTION_STARTTIME = 0; -- When the question was started
TRIVIA_TIME_RECORD = {}; -- Records the quickest time

TRIVIA_SCORES = {}; -- The scores table
TRIVIA_SCHEDULE = {}; -- The array used for scheduling events

INVALID_COMMAND = RED .. "Invalid Command Entered. " .. WHITE .. "Try '/trivia help'";

TRIVIA_UPDATEINTERVAL = 0.5; -- How often the OnUpdate code will run (in seconds)

-- Load Function
function Trivia_OnLoad()
	-- Register Events
	this:RegisterEvent("CHAT_MSG_CHANNEL");    
	this:RegisterEvent("CHAT_MSG_RAID");		
	this:RegisterEvent("CHAT_MSG_SAY");		
	this:RegisterEvent("CHAT_MSG_PARTY");		
	this:RegisterEvent("CHAT_MSG_GUILD");
	this:RegisterEvent("ADDON_LOADED");

    --Register Slash Command
  SLASH_TRIVIA1 = "/trivia";
  SlashCmdList["TRIVIA"] = Trivia_Command;


end

function Trivia_OnUpdate(elapsed)
	-- OnUpdate
	this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + elapsed; 	

	if (this.TimeSinceLastUpdate > TRIVIA_UPDATEINTERVAL) then
		Trivia_DoSchedule();
		this.TimeSinceLastUpdate = 0;
	end
end


-- Slash Command
function Trivia_Command(cmd)

	-- Convert to lower case
	cmd = string.lower(cmd);

	local msgArgs = {};
	local numArgs = 0;

	-- Search for seperators in the string and return
	-- the separated data.
	for value in string.gfind(cmd, "[^ ]+") do
		numArgs = numArgs + 1;
		msgArgs[numArgs] = value;
	end -- end for
	
	-- Get the number of arguments
	--numArgs = table.getn(msgArgs);
    
	if (numArgs == 0) then
		-- Show the help screen
		Trivia_Help();
        
	elseif (numArgs == 1) then
		if (msgArgs[1] == "skip") then
			-- Skip a question
			Trivia_SkipQuestion();
			Trivia_ConsoleMessage("Question skipped");
		elseif (msgArgs[1] == "shuffle") then
			-- Restart and reshuffle the questions
			Trivia_UnSchedule("all"); -- Stop the current question
			Trivia_ConsoleMessage("Questions shuffled");
			Trivia_SendMessage("Questions shuffled. Restarting with a new question in 5 seconds");
			Trivia_RandomiseOrder();
			Trivia_Schedule("NEXT_QUESTION", 5); -- Schedule a new one
		elseif (msgArgs[1] == "stop") then
			-- Stop the bot
			Trivia_Stop();
		elseif (msgArgs[1] == "qlist") then
			Trivia_ConsoleMessage("Select question list: ");
			Trivia_ConsoleMessage("normal - Mixed questions.");
			Trivia_ConsoleMessage("wow - World of Warcraft questions.")
			Trivia_ConsoleMessage("geography - Geography questions.")
		elseif (msgArgs[1] == "clear") then
			-- Clear the scores
			TRIVIA_SCORES = {};
			TRIVIA_TIME_RECORD = {["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone"};
			Trivia_ConsoleMessage("Trivia: Scores cleared.");
			Trivia_SendMessage("Scores cleared.");
		elseif (msgArgs[1] == "start") then
			-- Start the bot
			Trivia_ConsoleMessage("Trivia started in channel " .. TRIVIA_CHANNEL);
			Trivia_ConsoleMessage("First question coming up!");
            Trivia_Schedule("NEXT_QUESTION", 2);
		elseif (msgArgs[1] == "help") then
			Trivia_Help();
		elseif (msgArgs[1] == "channel") then
			-- Produce an error
			Trivia_ConsoleMessage("Usage: /trivia channel <channel name>");
			Trivia_ConsoleMessage("Try SAY|PARTY|RAID|GUILD|<custom channel>");
		else
			Trivia_ErrorMessage("Invalid Command - Try '/trivia help'");
		end
	elseif (numArgs == 2) then
		if (msgArgs[1] == "channel") then
			-- Leave the old channel first
			if (GetChannelName(TRIVIA_CHANNEL) > 0) then
				LeaveChannelByName(TRIVIA_CHANNEL);
			end
			
			-- Set the new channel type
			if (msgArgs[2] == "guild") then
				TRIVIA_CHANNEL = "GUILD";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "say") then
				TRIVIA_CHANNEL = "SAY";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "party") then
				TRIVIA_CHANNEL = "PARTY";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "raid") then
				TRIVIA_CHANNEL = "RAID";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			else
				-- Joining a new private channel
				NEW_TRIVIA_CHANNEL = msgArgs[2];
				Trivia_ChangeChannel();
			end
				
		elseif (msgArgs[1] == "qlist") then
			if (not TRIVIA_ENABLED) then
				if (msgArgs[2] == "normal") then
					Trivia_ConsoleMessage("Normal question set selected");
					TRIVIA_QLIST = "normal";
					TRIVIA_QUESTIONS = NORMAL_TRIVIA_QUESTIONS;
					TRIVIA_ANSWERS1 = NORMAL_TRIVIA_ANSWERS1;
					TRIVIA_ANSWERS2 = NORMAL_TRIVIA_ANSWERS2;
					TRIVIA_ANSWERS3 = NORMAL_TRIVIA_ANSWERS3;
          TRIVIA_ANSWERS4 = NORMAL_TRIVIA_ANSWERS4;
          TRIVIA_ANSWERS5 = NORMAL_TRIVIA_ANSWERS5;
          TRIVIA_ANSWERS6 = NORMAL_TRIVIA_ANSWERS6;
          TRIVIA_ANSWERS7 = NORMAL_TRIVIA_ANSWERS7;
          TRIVIA_ANSWERS8 = NORMAL_TRIVIA_ANSWERS8;
					Trivia_RandomiseOrder();
				elseif (msgArgs[2] == "wow") then
					Trivia_ConsoleMessage("WoW question set selected");
					TRIVIA_QLIST = "wow";
					TRIVIA_QUESTIONS = WOW_TRIVIA_QUESTIONS;
					TRIVIA_ANSWERS1 = WOW_TRIVIA_ANSWERS1;
					TRIVIA_ANSWERS2 = WOW_TRIVIA_ANSWERS2;
					TRIVIA_ANSWERS3 = WOW_TRIVIA_ANSWERS3;
          TRIVIA_ANSWERS4 = WOW_TRIVIA_ANSWERS4;
          TRIVIA_ANSWERS5 = WOW_TRIVIA_ANSWERS5;
          TRIVIA_ANSWERS6 = WOW_TRIVIA_ANSWERS6;
          TRIVIA_ANSWERS7 = WOW_TRIVIA_ANSWERS7;
          TRIVIA_ANSWERS8 = WOW_TRIVIA_ANSWERS8;
					Trivia_RandomiseOrder();
				elseif (msgArgs[2] == "geography" or msgArgs[2] == "geog") then
					Trivia_ConsoleMessage("Geography question set selected");
					TRIVIA_QLIST = "geography";
					TRIVIA_QUESTIONS = GEOGRAPHY_TRIVIA_QUESTIONS;
					TRIVIA_ANSWERS1 = GEOGRAPHY_TRIVIA_ANSWERS1;
					TRIVIA_ANSWERS2 = GEOGRAPHY_TRIVIA_ANSWERS2;
					TRIVIA_ANSWERS3 = GEOGRAPHY_TRIVIA_ANSWERS3;
          TRIVIA_ANSWERS4 = GEOGRAPHY_TRIVIA_ANSWERS4;
          TRIVIA_ANSWERS5 = GEOGRAPHY_TRIVIA_ANSWERS5;
          TRIVIA_ANSWERS6 = GEOGRAPHY_TRIVIA_ANSWERS6;
          TRIVIA_ANSWERS7 = GEOGRAPHY_TRIVIA_ANSWERS7;
          TRIVIA_ANSWERS8 = GEOGRAPHY_TRIVIA_ANSWERS8;
					Trivia_RandomiseOrder();
				else
					Trivia_ConsoleMessage("Unrecognised question set. Try '/trivia qlist'");
				end
			else
				Trivia_ConsoleMessage("Stop the trivia bot first!");
			end
		else
			Trivia_ErrorMessage("Invalid Command - Try '/trivia help'");
		end
	else
		Trivia_ErrorMessage("Invalid Command - Try '/trivia help'" );
	end

end
	
-- Event Handler
function Trivia_OnEvent(event)

	if (event == "ADDON_LOADED") then
		if (not TRIVIA_LOADED) then
			--Start in the 'off' state
			TRIVIA_ENABLED = false;
			
			-- Send a message
			Trivia_ConsoleMessage("Version" .. TRIVIA_VERSION .. " loaded.");
			
			-- Load the saved variables
			if (not TRIVIA_CHANNEL) then
				TRIVIA_CHANNEL = "triviatest"; -- The default used (private chan, guild, say, party etc)
			end
			
			if (not TRIVIA_QLIST) then
				TRIVIA_QLIST = "wow"; -- Default question list
			end
			
			-- Auto-Join the channel (probably annoying)
			--if (GetChannelName(TRIVIA_CHANNEL) <= 0) then
				--NEW_TRIVIA_CHANNEL = TRIVIA_CHANNEL;
				--Trivia_ChangeChannel();
			--end
		
			-- Load the questions
			TRIVIA_QUESTIONS = WOW_TRIVIA_QUESTIONS;
			TRIVIA_ANSWERS1 = WOW_TRIVIA_ANSWERS1;
			TRIVIA_ANSWERS2 = WOW_TRIVIA_ANSWERS2;
			TRIVIA_ANSWERS3 = WOW_TRIVIA_ANSWERS3;
      TRIVIA_ANSWERS4 = WOW_TRIVIA_ANSWERS4;
      TRIVIA_ANSWERS5 = WOW_TRIVIA_ANSWERS5;
      TRIVIA_ANSWERS6 = WOW_TRIVIA_ANSWERS6;
      TRIVIA_ANSWERS7 = WOW_TRIVIA_ANSWERS7;
      TRIVIA_ANSWERS8 = WOW_TRIVIA_ANSWERS8;
			
			TRIVIA_TIME_RECORD = {["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone"};
			
			-- Generate the question order.
			Trivia_RandomiseOrder();
			
			-- Set loaded state
			TRIVIA_LOADED = true;
		end
		
	elseif (event == "CHAT_MSG_CHANNEL") then
		local msg = arg1;
		local player = arg2;
        local channel = string.lower(arg9);

        if( (msg and msg ~= nil) and (player and player ~= nil) and (channel ~= nil) ) then
            if(channel == TRIVIA_CHANNEL) then
                if ( string.lower(msg) == "score" ) then
                    Trivia_WhisperScore(player);
    		    elseif ( TRIVIA_ENABLED ) then
                    Trivia_CheckAnswer(player, msg);
                end
            end
		end
	
	elseif ((event == "CHAT_MSG_SAY" or event == "CHAT_MSG_GUILD"
		 or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY") and TRIVIA_ENABLED) then
		
		-- Something was said, and the bot is on
		local msg = arg1;
		local player = arg2;

        if( (msg and msg ~= nil) and (player and player ~= nil)) then
			Trivia_CheckAnswer(player, msg);
		end
		
	elseif (event == "RETRY_CHANNEL_CHANGE") then
		Trivia_ChangeChannel();
		
	elseif (event == "NEXT_QUESTION") then
		TRIVIA_ENABLED = true;
		Trivia_AskQuestion();
		
	elseif (event == "QUESTION_TIMEOUT") then
		Trivia_QuestionTimeout();
		
	elseif (event == "QUESTION_WARN") then
		Trivia_SendMessage("20 seconds left!");
		
	elseif (event == "REPORT_SCORERS") then
		Trivia_ReportScores();
		
	elseif (event == "SHOW_ANSWER") then
		Trivia_SendMessage("The correct answer was: " .. TRIVIA_ANSWERS1[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]]);
	end
	
end

function Trivia_Help()
	
	-- Prints instructions
	Trivia_ConsoleMessage("'/trivia channel [SAY|PARTY|RAID|GUILD|<custom channel>]' - Sets the trivia channel.");
  Trivia_ConsoleMessage("'/trivia start' - Starts the trivia game.");
  Trivia_ConsoleMessage("'/trivia stop' - Stops the current game.");
	Trivia_ConsoleMessage("'/trivia skip' - Skips the current question.");
	Trivia_ConsoleMessage("'/trivia shuffle' - Shuffles the questions (restarts from beginning).");
	Trivia_ConsoleMessage("'/trivia clear' - Clears the scores.");
	Trivia_ConsoleMessage("'/trivia qlist [wow|normal]' Select the question list.");
	Trivia_ConsoleMessage("'/trivia help' shows this information.");
	
end

function Trivia_RandomiseOrder()
	-- Randomise the order of the questions
	TRIVIA_QUESTION_ORDER = {};
	
	-- Initialise the table
	local noOfQuestions = table.getn(TRIVIA_QUESTIONS);
	local n = 1;
	
	while (n <= noOfQuestions) do
		TRIVIA_QUESTION_ORDER[n] = n;
		n = n + 1;
	end
	
	local tmp, random;
	local i;
	local j = 5;
	
	while (j > 0) do
		i = 1;
		-- Swap each element with a random element
		while (i <= noOfQuestions) do
			random = math.random(noOfQuestions);
			tmp = TRIVIA_QUESTION_ORDER[i];
			TRIVIA_QUESTION_ORDER[i] = TRIVIA_QUESTION_ORDER[random]
			TRIVIA_QUESTION_ORDER[random] = tmp;
			i = i + 1;
		end
		
		-- Decrement J
		j = j - 1
	end
	
end

-- Channel changer
function Trivia_ChangeChannel()
	
	-- Check the old channel is really gone

	if (GetChannelName(TRIVIA_CHANNEL) > 0) then
		-- It still exists, try to leave it, and re-try this method.
		LeaveChannelByName(TRIVIA_CHANNEL);
		Trivia_Schedule("RETRY_CHANNEL_CHANGE", 1);
	else
		-- The channel is gone, begin joining a new one
	
		-- Protect global channels
    local protected_channel = {"general","trade","lookingforgroup","guildrecruitment","localdefence","worlddefence"}
    local protected = false
    for _,channel in ipairs(protected_channel) do
      if string.find(NEW_TRIVIA_CHANNEL,"^"..channel.."[.]*")~=nil then
        protected = channel
        break
      end
    end
		if protected ~= false then
			-- Announce protected Channel
			Trivia_ErrorMessage("Channel '" .. NEW_TRIVIA_CHANNEL .. "' contains a protected keyword: " .. protected .. ", unable to change channel.");
      Trivia_ErrorMessage("Spamming a global server channel can get you muted or even banned.");
			JoinChannelByName(TRIVIA_CHANNEL);
			NEW_TRIVIA_CHANNEL = TRIVIA_CHANNEL;
			ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, TRIVIA_CHANNEL);
		else
			-- Set and join the channel
			JoinChannelByName(NEW_TRIVIA_CHANNEL);
			ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, NEW_TRIVIA_CHANNEL);

		end
	
		-- Check the channel exists now
		if (GetChannelName(NEW_TRIVIA_CHANNEL) > 0) then
			-- Finalise the Change
			TRIVIA_CHANNEL = NEW_TRIVIA_CHANNEL;
	
			-- Announce the action
			Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);

		else
			-- It doesn't exist yet, re-try
			Trivia_Schedule("RETRY_CHANNEL_CHANGE", 1);
		end
	end

end


-- Asks a question
function Trivia_AskQuestion()

	TRIVIA_ACTIVE_QUESTION = TRIVIA_ACTIVE_QUESTION + 1;

	-- Check there is questions left
	if (TRIVIA_ACTIVE_QUESTION == (table.getn(TRIVIA_QUESTIONS) + 1)) then
		-- Reshuffle the order
		Trivia_RandomiseOrder();
		TRIVIA_ACTIVE_QUESTION = 1;
		Trivia_ConsoleMessage("Out of questions... Reshuffled and restarted.");
	end
	
    Trivia_SendMessage("Q: " .. TRIVIA_QUESTIONS[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]]);
	TRIVIA_QUESTION_STARTTIME = GetTime();
    Trivia_Schedule("QUESTION_TIMEOUT", TRIVIA_QUESTION_TIMEOUT);
	Trivia_Schedule("QUESTION_WARN", TRIVIA_QUESTION_TIMEWARN);
end

-- Answers the question and prepares the next if no one successfully answered the question
function Trivia_QuestionTimeout()
    Trivia_SendMessage("Time is up! No correct answer was given.");
	
	-- Report the scores every 5 questions
	if (TRIVIA_SCORE_REPORT == 1) then
		Trivia_Schedule("SHOW_ANSWER", 4);
		Trivia_Schedule("REPORT_SCORERS", 8);
		Trivia_Schedule("NEXT_QUESTION", 16);
		TRIVIA_SCORE_REPORT = 5;
	else
		TRIVIA_SCORE_REPORT = TRIVIA_SCORE_REPORT - 1;
		
		-- Schedule the next question
		Trivia_Schedule("SHOW_ANSWER", 4);
		Trivia_Schedule("NEXT_QUESTION", 8);
	end
	
end

-- Skip a question
function Trivia_SkipQuestion()

	if (TRIVIA_ENABLED == true) then
		Trivia_SendMessage("Question was skipped.");
		Trivia_UnSchedule("all");
		
		-- Show the answer anyway (for those that wanted to know)
		Trivia_Schedule("SHOW_ANSWER", 2);
		
		-- Schedule the next question
		Trivia_Schedule("NEXT_QUESTION", 4);
	end
	
end

function Trivia_Stop()
	-- Clear all scheduled events
    Trivia_UnSchedule("all");
    TRIVIA_ENABLED = false;
    Trivia_SendMessage("Trivia bot stopped.");
	Trivia_ConsoleMessage("Trivia bot stopped.")
end

function Trivia_CheckAnswer(player, msg)
    if ((string.lower(msg) == string.lower(TRIVIA_ANSWERS1[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or
        (TRIVIA_ANSWERS2[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS2[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or
        (TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or 
        (TRIVIA_ANSWERS4[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or 
        (TRIVIA_ANSWERS5[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or 
        (TRIVIA_ANSWERS6[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or 
        (TRIVIA_ANSWERS7[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]])) or
        (TRIVIA_ANSWERS8[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]] ~= nil and string.lower(msg) == string.lower(TRIVIA_ANSWERS3[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]]))) then
        -- Correct answer
		
		 Trivia_SendMessage("That is the correct answer, "..player..".");
		 
		-- Unschedule warnings and timeout
		Trivia_UnSchedule("all");
		
		-- Time the answer
		local timeTaken = GetTime() - TRIVIA_QUESTION_STARTTIME;
		
		-- Round it 
		timeTaken = math.floor(timeTaken  * 10^2 + 0.5) / 10^2;
		
		-- Announce if it was quick
		if (timeTaken < TRIVIA_TIME_RECORD["time"]) then
			Trivia_SendMessage("NEW RECORD! Answered in: " .. timeTaken .. " sec");
			TRIVIA_TIME_RECORD["holder"] = player;
			TRIVIA_TIME_RECORD["time"] = timeTaken;
		end
		
        local score = TRIVIA_SCORES[player];
        if (score) then
			score = score + 1;
        else
			score = 1;
        end

        TRIVIA_SCORES[player] = score;
		
		-- Report the scores every 5 questions
		if (TRIVIA_SCORE_REPORT == 1) then
			Trivia_Schedule("REPORT_SCORERS", 4);
			Trivia_Schedule("NEXT_QUESTION", 14);
			TRIVIA_SCORE_REPORT = 5;
		else
			TRIVIA_SCORE_REPORT = TRIVIA_SCORE_REPORT - 1;
			
			-- Schedule the next question
			Trivia_Schedule("NEXT_QUESTION", 8);
		end
		

		
		-- Prevent further answers
		TRIVIA_ENABLED = false;
		
    end
end

function Trivia_ReportScores()
	
	-- Sort the table
	local TRIVIA_SORTED = {};
	
	for player, score in TRIVIA_SCORES do
		-- Add them to the sorting table
		table.insert(TRIVIA_SORTED, {["player"] = player, ["score"] = score});
	end
	
	table.sort(TRIVIA_SORTED, function(v1, v2)
		return v1["score"] > v2["score"];
		end);

	Trivia_SendMessage("Standing so far:");
		-- Report the top 3 scorers
	for id, record in TRIVIA_SORTED do
		if (id <= 3) then
			-- Report the top 3
			
			-- Ensure correct grammar.
			local ess = "s";
			if (record["score"] == 1) then
				ess = "";
			end

			Trivia_SendMessage(id .. "]: " .. record["player"] .. " (" .. record["score"] .." point" .. ess .. ")");
			
		end
	end
	
	-- Speed record holder
	if (TRIVIA_TIME_RECORD["holder"] ~= "noone") then
		Trivia_SendMessage("Speed Record: " .. TRIVIA_TIME_RECORD["holder"] .. " in " .. TRIVIA_TIME_RECORD["time"] .. " sec");
	end
	
	
end


function Trivia_ClearTells(player)
	TRIVIA_TELLS[player] = nil;
end


function Trivia_DoSchedule()
		-- TO DO: Make some stuff
	if (TRIVIA_SCHEDULE ~= nil)	then
		for id, events in TRIVIA_SCHEDULE do
			-- Get the time of each event
			-- If it should be run (i.e. equal or less than current time)
			if (events["time"] <= GetTime()) then
				Trivia_OnEvent(events["name"]);
				Trivia_UnSchedule(id);
			end
		end
	end
end

function Trivia_Schedule(name, time)
		-- Schedule an event
		thisEvent = {["name"] = name, ["time"] = GetTime() + time};
		table.insert(TRIVIA_SCHEDULE, thisEvent);
end

function Trivia_UnSchedule(id)
		-- Unschedule an event
		
		if (id == "all") then
			TRIVIA_SCHEDULE = {};
		else
			table.remove(TRIVIA_SCHEDULE, id);
		end
end


function Trivia_SendMessage(msg)
	-- Send a message to the trivia channel
	
	-- Append the trivia tag to each message 
	msg = "[Trivia]: " .. msg;
	
	-- Send the message to the right channel.
	if (TRIVIA_CHANNEL == "GUILD") then
		SendChatMessage(msg, "GUILD");
	elseif (TRIVIA_CHANNEL == "SAY") then
		SendChatMessage(msg, "SAY");
	elseif (TRIVIA_CHANNEL == "PARTY") then
		SendChatMessage(msg, "PARTY");
	elseif (TRIVIA_CHANNEL == "RAID") then
		SendChatMessage(msg, "RAID");
	elseif (TRIVIA_CHANNEL ~= nil) then
	
		-- Check the channel exists, and send
		id = GetChannelName(TRIVIA_CHANNEL);
		
		if (id > 0) then
			SendChatMessage(msg, "CHANNEL", nil, id);
		else
			-- Channel send error, stop the current game
			Trivia_ErrorMessage("Unable to send to channel.");
			Trivia_ErrorMessage("Reset channel with '/trivia channel'");
			Trivia_ErrorMessage("Current Trivia game stopped.");
			Trivia_UnSchedule("all");
			TRIVIA_ENABLED = false;
		end

	end
	
end

function Trivia_ConsoleMessage(msg)
	-- Check the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = MAGENTA .. "Trivia: " .. WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

function Trivia_ErrorMessage(msg)
	-- Check the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = MAGENTA .. "Trivia: " .. RED .. "ERROR! - " .. WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end
