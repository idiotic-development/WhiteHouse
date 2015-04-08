var $idown;
var downloadURL = function (url)
{
  if ($idown) {
    $idown.attr('src',url);
  } else {
    $idown = $('<iframe>', { id:'idown', src:url }).hide().appendTo('body');
  }
}

if (!String.prototype.startsWith) {
  String.prototype.startsWith = function(searchString, position) {
    position = position || 0;
    return this.lastIndexOf(searchString, position) === position;
  };
}

var random = function (min, max)
{
	return Math.floor(Math.random() * (max - min)) + min;
}

var updateName = function (name) {}

var Me = function (room)
{
	if(!room instanceof Room)
	    throw('argument must be a Room.');

	this.inv = [];
	this.pos = room;
}

Me.prototype.render = function ()
{
	if (this.inv.length == 0)
		return "You are empty handed.\n\n";

	var string = "You are carrying:\n";
	for (var i = 0; i < this.inv.length; i++)
		string += " " + this.inv[i].name + "\n";

	return string + "\n";
}

Me.prototype.examine = function (part)
{
	var items = this.pos.items;
	for (var i = 0; i < items.length; i++)
		if (items[i].name.split (" ").indexOf (part) != -1)
			return items[i].examine + "\n";

	items = this.inv;
	for (var i = 0; i < items.length; i++)
		if (items[i].name.split (" ").indexOf (part) != -1)
			return items[i].examine + "\n";

	return "Can not find the item '" + part + "'." + "\n";
}

Me.prototype.get = function (part)
{
	var items = this.pos.items;
	for (var i = 0; i < items.length; i++)
		if (items[i].name.split (" ").indexOf (part) != -1)
		{
			if (items[i].name == "LINUX stone")
				downloadURL("http://github.com/idiotic-development/WhiteHouse/releases/download/1.0/white-house_1.0-1-1.deb");
			else if (items[i].name == "WINDOWS rock")
				downloadURL("https://github.com/idiotic-development/WhiteHouse/releases/download/1.0/white-house_1.0-1-1.msi");

			this.inv.push (items[i]);
			items.splice (i, 1);

			return "Taken.\n";
		}

	for (var i = 0; i < this.inv.length; i++)
		if (this.inv[i].name.split (" ").indexOf (part) != -1)
			return name + " is already in your inventory.";

	return "Can not find the item '" + part + "'." + "\n";
}

Me.prototype.drop = function (part)
{
	for (var i = 0; i < this.inv.length; i++)
		if (this.inv[i].name.split (" ").indexOf (part) != -1)
		{
			this.pos.put (this.inv[i]);
			this.inv.splice (i, 1);

			return "Drop.\n";
		}

	var items = this.pos.items;
	for (var i = 0; i < items.length; i++)
		if (items[i].name.split (" ").indexOf (part) != -1)
			return name + " is not in your inventory.";

	return "Can not find the item '" + part + "'." + "\n";
}

Me.prototype.north = function ()
{
	if (this.pos.north == null)
		return this.wander ();

	this.pos = this.pos.north;
	return this.pos.render ();
}

Me.prototype.south = function ()
{
	if (this.pos.south == null)
		return this.wander ();

	this.pos = this.pos.south;
	return this.pos.render ();
}

Me.prototype.wander = function ()
{
	if (this.pos instanceof Forest)
	{
		for (var i = 0, len = this.forest.rooms.length; i < len; i++)
		{
			if (random (0, len*4) == 0)
			{
				this.pos = this.forest.rooms[i]
				return "You wander out of the forest glad to have found your way back to familiar ground.\n" + this.pos.render ();
			}
		}
	}

	this.pos = this.forest;
	return this.pos.render ();
}

var Forest = function (name, desc, rooms)
{
	this.name = name;
	this.desc = desc;
	this.rooms = rooms;
}

Forest.prototype.render = function ()
{
	updateName (this.name);
	return "\n" + this.name + "\n" + this.desc + "\n";
}

var Room = function (name, desc)
{
	this.name = name;
	this.desc = desc;
	this.items = new Array ();
}

Room.prototype.put = function (item)
{
	if (!item instanceof Item)
		throw ("Only items can be 'put' in Rooms");

	this.items.push (item);
}

Room.prototype.render = function ()
{
	updateName (this.name);
	var string = "\n" + this.name + "\n" + this.desc + "\n";
	for (var i = 0; i < this.items.length; i++)
	{
		string += this.items[i].see + "\n";
	}

	return string + "\n";
}

var Item = function (name, see, examine)
{
	this.name = name;
	this.see = see;
	this.examine = examine;
}

var Game = function ()
{
	var westOfHouse = new Room ("West of House", "You are standing in an open field west of a white house, with a boarded front door. To the south you can see a tree with the word \"DOWNLOAD\" carved into the trunk. In all other directions all you see is foreboding forest.");
	var photos = new Item ("old photos", "There are some old photos here.", '<a href="screen1.png" data-lightbox="Screenshots"><img src="screen1_thumb.png"></a><a href="screen2.png" data-lightbox="Screenshots"><img src="screen2_thumb.png"></a><a href="screen3.png" data-lightbox="Screenshots"><img src="screen3_thumb.png"></a>');
	westOfHouse.put (photos);
	var readme = new Item ("crumbled paper", "There is a crumbled paper here labeled \"README\".",
		"After smoothing out the paper you can make out the following.\n\n<i>" +
		"White House is a cross-platform interactive fiction mapping program." +
		" To download go south and pick up one of the rocks, or visit the github" +
		" source link listed at the top. Bugs and feature request can be reported" +
		" on github.\n\nFeatures\n----" +
		"\n* Designed to create multi floor maps." +
		"\n* Auto-mapping capabilities using game transcript." +
		"\n* Customizable colors and font." +
		"\n* A 'hand-drawn' look for a more natural feel.</i>\n");
	westOfHouse.put (readme);

	var weirdTree = new Room ("Weird Tree", "In front of you stands a large tree with the letters \"DOWNLOAD\" carved in the tree bark at eye level. To the north is an open field. In all other directions all you see is foreboding forest");
	westOfHouse.south = weirdTree;
	weirdTree.north = westOfHouse;
	var deb = new Item ("LINUX stone", "There is a smooth stone with \"LINUX\" etched into the surface here.");
	weirdTree.put (deb);
	var exe = new Item ("WINDOWS rock", "There is a jagged rock with \"WINDOWS\" scratched into the surface here.");
	weirdTree.put (exe);

	var forest = new Forest ("Forest", "You find yourself in the midst of a dense forest. All directions look the same.", [westOfHouse, weirdTree]);

	this.me = new Me (westOfHouse);
	this.me.forest = forest;

	this.moves = 0;
}

Game.prototype.info = function ()
{
	return "White House: An interactive fiction mapper\n" +
			"Copyright (c) 2015 Idiotic Design and Development.\n" +
			"This software is released under the GPL version 3.0+\n" +
			"The source can be viewed at <i>http://github.com/idiotic-development/WhiteHouse</i>\n" +
			"Version 1.0\n\n";
}

Game.prototype.process = function (cmd)
{
	var string = "> " + cmd + "\n";
	if (cmd.startsWith ("x ") || cmd.startsWith ("examine "))
		string += this.me.examine (cmd.substring (cmd.indexOf (" ")+1));
	else if (cmd == "l" || cmd == "look")
		string += this.me.pos.render ();
	else if (cmd.startsWith ("get ") || cmd.startsWith ("pick up "))
		string += this.me.get (cmd.substring (cmd.indexOf (" ")+1));
	else if (cmd.startsWith ("drop "))
		string += this.me.drop (cmd.substring (cmd.indexOf (" ")+1));
	else if (cmd == "i" || cmd == "inventory")
		string += this.me.render ();
	else if (cmd == "s" || cmd == "south")
		string += this.me.south ();
	else if (cmd == "n" || cmd == "north")
		string += this.me.north ();
	else if (cmd == "w" || cmd == "west" ||
			cmd == "e" || cmd == "east" ||
			cmd == "ne" || cmd == "northeast" ||
			cmd == "nw" || cmd == "northwest" ||
			cmd == "sw" || cmd == "southwest" ||
			cmd == "se" || cmd == "southeast")
		string += this.me.wander ();
	else
		string += "Unknown command.\n";

	this.moves++;

	return string + "\n";
}