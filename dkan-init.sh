#!/bin/bash
mkdir dkan &&
#mv !(dkan) dkan/.
#find . ! -regex '.*/dkan' ! -regex '.' -exec mv '{}' dkan \; &&
shopt -s extglob dotglob &&
mv !(dkan) dkan &&
shopt -u dotglob &&
# find . ! -regex '.*/dkan' ! -regex '.' -exec echo "'{}'" \; &&
cp dkan/.ahoy/starter.ahoy.yml .ahoy.yml &&
echo "A DKAN Drupal site has been initialized. Type 'ahoy' for DKAN commands."
which ahoy || echo "Notice: ahoy is not installed. Follow the instructions at https://github.com/devinci-code/ahoy to install it."
