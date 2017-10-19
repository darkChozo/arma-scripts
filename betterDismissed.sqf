/*
 * betterDismissed.sqf
 * Scripted waypoint that simulates off duty behaviour. Inspired by the (terrible)
 * vanilla Dismissed waypoint.
 *
 * A group given a betterDismissed waypoint will split up into small subgroups
 * of 1-4 men, spread out over the specified area. These subgroups will act as
 * though they're hanging out, by facing each other, using safe animations, and
 * sitting down. Ocasionally, subgroups will relocate to new locations in an
 * equally casual manner. Waypoint behaviour is terminated when the group enters
 * combat mode.
 *
 * Demo - https://www.youtube.com/watch?v=Ld79QWukwEs
 * Latest version - https://github.com/darkChozo/arma-scripts/blob/master/betterDismissed.sqf
 *
 * betterDismissed is SP and MP-compatable.
 *
 * Parameters:
 *    radius (optional): radius of the loiter area. Default 30m.
 *
 * Usage: place a scripted waypoint on the position where you want units to chill
 *    Set the waypoint script parameter to:
 *	      betterDismissed.sqf
 *		  betterDismissed.sqf [30]   <-- to set the waypoint radius
 */


params ["_grp","_pos","_target",["_radius",30]];

_units = units _grp;
_subGroups = [];

// split group up into subGroups
_i = 0;
while {_i < count _units} do {
	_subGroup = [];
	_size = _i + 2 + floor random 3;
	if (_size > count _units) then {_size = count _units};
	while {_i < _size} do {
		_subGroup pushBack (_units select _i);
		_i = _i + 1;
	};
	_subGroups pushBack _subGroup;
};

_grp setBehaviour "SAFE";
_grp setSpeedMode "LIMITED";

_findChillSpot = {
	params ["_units","_pos","_radius"];
	_center = [[[_pos,_radius]]] call BIS_fnc_randomPos;
	_blackList = [];
	{
		sleep random 1;
		_targetPos = [[[_center,4]],_blackList] call BIS_fnc_randomPos;
		_x doMove _targetPos;
		_blackList pushBack [_targetPos,2.5];
		_x setBehaviour "SAFE";
		_x setSpeedMode "LIMITED";
		[_x,_center] spawn {
			params ["_unit","_center"];
			sleep 1;
			waitUntil {sleep 3; speed _unit == 0 && _unit distance _center < 5};
			sleep 1;
			_unit lookAt ((_center select [0,2]) + [1.8]); // look at a point at about head height
			sleep 2;
			if (random 1 > .7) then {
				_unit action ["SitDown",_this select 0];
			};
		};
	} forEach _units;
};

{
	[_x,_pos,_radius] call _findChillSpot;
} forEach _subGroups;

// subthread that relocates a random subgroup every so often
[_grp,_pos,_subGroups,_findChillSpot,_radius] spawn {
	params ["_grp","_pos","_subGroups","_findChillSpot","_radius"];
	while { behaviour leader (_grp) == "SAFE" } do {
		sleep 60 + random 30;
		[selectRandom _subGroups,_pos,_radius] call _findChillSpot;
	};
};

waitUntil {behaviour (leader _grp) == "COMBAT"};

_grp setSpeedMode "NORMAL";