/*
	LU Headshot Script
	--------------------------------------------------
	Author: Juppi
*/

g_LocalPlayer <- FindLocalPlayer();

function onClientShot( pPlayer, iWeapon, iBodypart )
{
	// Apply this for weapons starting from shotgun only
	if ( ( iBodypart == BODYPART_HEAD ) && ( iWeapon > 3 ) )
	{
		g_LocalPlayer.RemoveLimb( BODYPART_HEAD ); // Remove head
		g_LocalPlayer.Health = 1; // Kill the player >:D (We need to use health=1, otherwise the script will think we want to suicide rather than get killed by someone)
	}
	
	return 1;
}

function onClientKill( pPlayer, iWeapon, iBodypart )
{
	if ( ( iBodypart == BODYPART_HEAD ) && ( iWeapon > 3 ) )
	{
		BigMessage( "~r~HEADSHOT", 3000, 3 );
	}
	
	return 1;
}

function onClientDeath( pKiller, iWeapon, iBodypart )
{
	if ( pKiller )
	{
		if ( ( iBodypart == BODYPART_HEAD ) && ( iWeapon > 3 ) )
		{
			BigMessage( "~r~HEADSHOT", 3000, 3 );
		}
	}
	
	return 1;
}
