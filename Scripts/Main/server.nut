class PlayerStats
{
	Score = 0;
	Deaths = 0;
	Cash = 0;
	Joins = 0;
	Logged = false;
	Connected = false;
	Password = null;
	PreviousData = false;
}

function onScriptLoad()
{
	print("[*] Loading modules...");
	LoadModule("lu_sqlite");
	LoadModule("lu_hashing");
	LoadModule("lu_ini");
	print("[*] Modules sucessfully loaded.");
	print("[*] Initializing database...");
	statDB <- sqlite_open("database.sqlite");
	stats <- array(128,null);
	print("[*] Database sucessfully initialized.");
	print("[*] Server started successfully.");
}

function onConsoleInput( cmd, text )
{
	if ( cmd == "createtable" )
	{
		sqlite_query( statDB, "CREATE TABLE Stats ( Name VARCHAR(32), Password VARCHAR(128), Score INT, Cash INT, Deaths INT, Joins INT )" );
		print("[*] Database successfully created");
	}
}

function onPlayerConnect(player)
{
	if ( player.Name == "UnknownPlayer" )
	{
		player.Name = "Guest ("+player.ID+")";
	}
	stats[player.ID] = PlayerStats();
	for ( local i = 0; i <= 30; i++ ) MessagePlayer("",player);
}

function onPlayerJoin(player)
{
	MessagePlayer("[#ffff00][*][#ffffff] Welcome to the server",player);
	local q = sqlite_query( statDB, "SELECT Score, Password, Cash, Deaths, Joins FROM Stats WHERE Name='" + player.Name + "'" );
	if ( sqlite_column_data( q, 0 ) != null )
	{
		stats[player.ID].PreviousData = true;
		stats[player.ID].Password = sqlite_column_data( q, 1 );
		stats[player.ID].Cash = sqlite_column_data( q, 2 );
		stats[player.ID].Deaths = sqlite_column_data( q, 3 );
		stats[player.ID].Joins = sqlite_column_data( q, 4 );
		MessagePlayer("[#ffff00][*][#ffffff] This account is registered, please login using /login < password >",player);
	}
	else
	{ 
		MessagePlayer("[#ffff00][*][#ffffff] This account is not registered, please register using /register < password >",player);
	}
	stats[player.ID].Joins++; 
	stats[player.ID].Connected = true;
	sqlite_free(q);
	player.Spawn();
}

function SaveAccount(player)
{
	local id = player.ID;
	if ( stats[player.ID].PreviousData )
	{
		local query = format("UPDATE Stats SET Score=%i, Cash=%i, Deaths=%i, Joins=%i WHERE Name='%s'",
		stats[id].Score, stats[id].Cash, stats[id].Deaths, stats[id].Joins,player.Name);
		sqlite_query(statDB,query);
	}
	else
	{
		local query = format("INSERT INTO Stats(Name, Score, Cash, Deaths, Joins) VALUES ('%s', %i, %i, %i, %i)",
		player.Name,stats[id].Score,stats[id].Cash,stats[id].Deaths,stats[id].Joins);	
		sqlite_query(statDB,query);
	}
	print("[*] Successfully saved account of "+player.Name);
	stats[id] = null;
}

function onPlayerPart(player,part)
{
	if ( stats[player.ID].Logged == true )
	{
		SaveAccount(player);
	}
}

function onPlayerAction(player,message)
{
	if ( stats[player.ID].Connected ) return 1;
	else return 0;
}

function onPlayerChat(player,message)
{
	if ( stats[player.ID].Connected ) return 1;
	else return 0;
}

function onPlayerSpawn(player,spawn)
{
	player.SetWeapon(1,1);
	player.SetWeapon(3,500);
	player.SetWeapon(4,500);
	player.SetWeapon(0,1);
}

function onPlayerCommand( player, cmd, text )
{
	if ( stats[player.ID].Connected )
	{
		switch ( cmd )
		{
			case "register":
	
				if ( text )
				{
					if ( stats[player.ID].Logged == false )
					{
						if ( stats[player.ID].PreviousData == false )
						{
							local query = format( "INSERT INTO Stats (Name, Password) VALUES ('%s','%s')", player.Name, text );
							sqlite_query(statDB,query);
							stats[player.ID].PreviousData = true;
							stats[player.ID].Password = text;
							stats[player.ID].Logged = true;
							print("[*] "+player.Name+" has registered");
							MessagePlayer("[#00ff00][*][#ffffff] You have been successfully registered",player);
                                 
						}
						else
							MessagePlayer("[#ff0000][*][#ffffff] You are already registered",player);
					}
					else
						MessagePlayer("[#ff0000][*][#ffffff] You are already logged in",player); 
				}
				else
					MessagePlayer("[#ff0000][*][#ffffff] Incorrect format. Usage: /register < password >",player);		
			break;

				
			case "login":


				if ( text )
				{
					if ( stats[player.ID].Logged == false )
					{
						if ( stats[player.ID].PreviousData == true )
						{
							if ( stats[player.ID].Password == text )
							{
								stats[player.ID].Logged = true;
								MessagePlayer("[#00ff00][*] [#ffffff]You have been successfully logged in",player);
							}
							else
								MessagePlayer("[#ff0000][*] [#ffffff]Invalid password",player); 
						}
						else
							MessagePlayer("[#ff0000][*][#ffffff] You are not registered. Use /register",player);
					}
					else
						MessagePlayer("[#ff0000][*][#ffffff] You are already logged in",player); 
				}
				else
					MessagePlayer("[#ff0000][*][#ffffff] Incorrect format. Usage: /login < password >",player);

			break;	

			case "stats":
			
				if ( text )
				{
					local target = GetPlayer(text);
					if ( target )
					{
						local ts = stats[target.ID];
						local ratio = ts.Score;
						if ( ts.Deaths != 0 )
						{
							ratio = ts.Score/ts.Deaths;
						}
						Message("[#808080][*][#ffffff] "+target.Name+"'s stats (Requested by "+player.Name+"): ");
						Message("[#808080][*][#ffffff] Kills: "+ts.Score+", Deaths: "+ts.Deaths+", Joins: "+ts.Joins);
						Message("[#808080][*][#ffffff] Cash: "+ts.Cash+", K/D Ratio: "+ratio);
					}
					else
						MessagePlayer("[#ff0000][*][#ffffff] Specified player not found",player);
				}
				else
					MessagePlayer("[#ff0000][*][#ffffff] Incorrect format. Usage: /stats < player name / ID >",player);

			break;
	
			case "cmds":
				
				MessagePlayer("[#ff00ff][*][#ffffff] Commands: /register, /login, /stats",player);

			break;
			
			default:
			
				MessagePlayer("[#ff0000][*][#ffffff] Unknown command! Type /cmds",player);
			
			break;
		}
	}
}

function onPlayerKill( killer, player, weapon, bodypart )
{
	stats[ killer.ID ].Score++;
	stats[ killer.ID ].Cash += 250;
	stats[ player.ID ].Deaths++;
	Message( "[#ff8000][*][#ffffff] " + killer.Name + " has killed " + player.Name + " (" + GetWeaponName( reason ) + ")" );
}
 
function onPlayerDeath( player, reason )
{
	stats[ player.ID ].Deaths++;
	Message("[#ff8000][*][#ffffff] "+player.Name+" has died");
}

function onPlayerUpdate(player)
{
	if ( stats[player.ID].Logged )
	{
		player.Score = stats[player.ID].Score;
		player.Cash = stats[player.ID].Cash;
	}
}

function GetPlayer( target )
{
	target = target.tostring();
	
	if ( IsNum( target ) )
	{
		target = target.tointeger();
		
		if ( FindPlayer( target ) ) return FindPlayer( target );
		else return null;
	}
	else if ( FindPlayer( target ) ) return FindPlayer( target );
	else return null;
}

function onPickupPickedUp( player, pickup )
{
	local model = pickup.Model;
	switch( model )
	{
		case 170:
			player.SetWeapon( 11, 15 );
		break;
		case 171:
			player.SetWeapon( 5, 750 );
		break;
		case 172:
			player.SetWeapon( 1, 1 );
		break;
		case 173:
			player.SetWeapon( 2, 500 );
		break;
		case 174:
			player.SetWeapon( 10, 15 );
		break;       
		case 175:
			player.SetWeapon( 8, 50 );
		break;
		case 176:
			player.SetWeapon( 4, 50 );
		break;
		case 177:
			player.SetWeapon( 7, 50 );
		break;
		case 178:
			player.SetWeapon( 3, 500 );
		break;
		case 180:
			player.SetWeapon( 6, 1000 );
		break;
		case 181:
			player.SetWeapon( 9, 250 );
		break;
		case 1362:
			player.Health = 100;
		break;
		case 1364:
			player.Armour = 100;
		break;
	}
}
