<VirtualHost *>
	ServerAdmin webmaster@example.com
	ServerName example.com
	ServerAlias www.example.com
	ErrorLog /home/sites/logs/example.com.error
	CustomLog /home/sites/logs/example.com.access combined
	DocumentRoot /home/sites/example.com.org/web

	<Directory /home/sites/example.com/web/>
 		Options Indexes FollowSymLinks
 		AllowOverride None
 		Order allow,deny
 		Allow from all
	</Directory>
</VirtualHost>
