CREATE USER 'quicksight_readonly'@'%' IDENTIFIED BY 'my_pass';
GRANT SELECT ON backend2024.* TO 'quicksight_readonly'@'%';
FLUSH PRIVILEGES;
