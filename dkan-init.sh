#!/usr/bin/env bash
# This allows us to use !(dkan) to move all the files into the dkan folder without recursion.
shopt -s extglob dotglob

mkdir dkan 2> /dev/null && echo "Created ./dkan folder.." || echo "DKAN folder already exists.. exiting."

mv !(dkan) dkan && echo "Moved all files into ./dkan.." || echo "Error moving files into ./dkan.. exiting."
shopt -u dotglob

cp dkan/.ahoy/starter.ahoy.yml .ahoy.yml && echo "Created an initial ahoy file at ./.ahoy.yml based on ./dkan/.ahoy/starter.ahoy.yml. Feel free to customize if you need."

echo "A DKAN Drupal site has been initialized. Type 'ahoy' for DKAN commands."
ahoy || echo "Notice: ahoy is not installed. Follow the instructions at https://github.com/devinci-code/ahoy to install it."
echo "To complete a dkan installation, run the following commands :"
echo "  ahoy dkan drupal-rebuild [DB_URL i.e. mysql://user:password@server/database_name]"
echo "  ahoy dkan remake && "
echo "  ahoy dkan reinstall && "
