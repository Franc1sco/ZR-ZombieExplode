#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <zombiereloaded>

#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "1.1"

new bool:g_ZombieExplode[MAXPLAYERS+1] = false;
new Handle:tiempo;


#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new g_ExplosionSprite;
new g_SmokeSprite;
new Float:iNormal[ 3 ] = { 0.0, 0.0, 1.0 };

public Plugin:myinfo =
{
    name = "SM Zombie Explode 3 edition",
    author = "Franc1sco steam: franug",
    description = "Kill zombies with knife",
    version = DATA,
    url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
    CreateConVar("sm_zombiexplode3_version", DATA, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_hurt", EnDamage);

    tiempo = CreateConVar("sm_zombiexplode3_time", "3.0", "Seconds that zombie have for catch to humans");

}

public OnConfigsExecuted()
{
	PrecacheSound(EXPLODE_SOUND, true);
	g_ExplosionSprite = PrecacheModel( "sprites/blueglow2.vmt" );
	g_SmokeSprite = PrecacheModel( "sprites/steam1.vmt" );
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{

        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsValidClient(attacker))
		return;

	if (IsPlayerAlive(attacker))
	{
           new client = GetClientOfUserId(GetEventInt(event, "userid"));


           if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client))
           {
             decl String:weapon[WEAPONS_MAX_LENGTH];
             GetEventString(event, "weapon", weapon, sizeof(weapon));
    
             if(StrEqual(weapon, "knife", false))
             {
                        g_ZombieExplode[client] = true;

                        PrintToChat(client, "\x04[SM_ZombieExplode3] \x05you have %f seconds to catch any human or you will die!", GetConVarFloat(tiempo),attacker);

                        CreateTimer(GetConVarFloat(tiempo), ByeZM, client);
             }
            }
        }

}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{

	    if (!IsValidClient(attacker))
		      return Plugin_Continue;

            if(g_ZombieExplode[attacker])
            {
                        g_ZombieExplode[attacker] = false;
                        PrintToChat(attacker, "\x04[SM_ZombieExplode3] \x05you have caught a human then you have saved!");
            }
            return Plugin_Continue;
}



public Action:ByeZM(Handle:timer, any:client)
{
 if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
 {
                        g_ZombieExplode[client] = false;

            		new Float:iVec[ 3 ];
		        GetClientAbsOrigin( client, Float:iVec );

			TE_SetupExplosion( iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, iNormal );
			TE_SendToAll();
			
			TE_SetupSmoke( iVec, g_SmokeSprite, 10.0, 3 );
			TE_SendToAll();
	
			EmitAmbientSound( EXPLODE_SOUND, iVec, client, SNDLEVEL_NORMAL );

                        ForcePlayerSuicide(client);
 }
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  g_ZombieExplode[client] = false;

}


