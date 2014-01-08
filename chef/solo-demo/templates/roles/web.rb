name 'web'
description 'Generic Web Server'
run_list "recipe[apache2::default]"
