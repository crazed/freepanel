#!/usr/bin/perl
use strict;
use Getopt::Std;
use Postfix;

############# CONFIGURATION OPTIONS ###############
use constant DEBUG      => 1; # 1 on 0 off
use constant DBERROR    => 1; # 1 on 0 off
use constant HOSTNAME   => "localhost";
use constant PORT       => "3306";
use constant USER       => "root";
use constant PASSWORD   => "";
use constant DATABASE   => "mail";
use constant USER_TB    => "mailbox";
use constant DOMAIN_TB  => "domain";
use constant ALIAS_TB   => "alias";
####################################################

my %options;
getopts("amrf:e:n:c:v:p:h:q:d:", \%options);

# make the initial object
my $pf = new DP::Postfix (HOSTNAME, PORT, USER, PASSWORD, DATABASE, 1, 1);

# connect to the database (soon to happen automatically)
$pf->dbConnect();

########################################### Settings #################################################
# set the name of the alias table
$pf->setAliasTable(ALIAS_TB);

# set the name of the domain table
$pf->setDomainTable(DOMAIN_TB);

# set the name of the user table
$pf->setUserTable(USER_TB);

# specify the alias table columns
$pf->setAliasCols(['address', 'goto']);

# specify the domain column
$pf->setDomainCol('domain');

# specify the user table columns
$pf->setUserCols(['name', 'username', 'quota', 'password']);

# this is the column that contains email addresses
$pf->setEmailIdentifier('username');

# this is the column that contains email addresses in the alias table
$pf->setAliasIdentifier('address');
######################################################################################################

processInput();
sub processInput
{
        # add user
        if ($options{a}) {
                my $quota;

		# adding a domain
                if ($options{d}) {
                        $pf->addDomain($options{d});
                        exit();
                }
 
                # in order to add user must have -a -e -n -p or -h
                if (!$options{e} || !$options{n}) {
                        usageHelp();
                }

                # check for quota
                if ($options{q}) {
                        # quota is stored in bytes but argument taken in MB
                        $quota = 1024 * 1024 * $options{q};
                }
                else {
                        $quota = 10485760;	# default to 10mb if nothing set
                }

                # make sure either a password or hash was sent
                if ($options{p}) {
                        # convert plain text to hash
                        my $hash = $pf->hash($options{p}, 'md5crypt');
			
			# add the user
			# note: add user must corrolate to setUserCols
			# ['name', 'username', 'quota', 'password']
                        $pf->addUser([$options{n}, $options{e}, $quota, $hash]);
                }
                elsif ($options{h}) {  
                        $pf->addUser([$options{n}, $options{e}, $quota, $options{h}]);
                }   
                else {
                        usageHelp();
                }

                exit();

        }

        # remove user requires -e option
        if ($options{r}) {
                if ($options{e}) {
			# delete a user
                        $pf->delUser($options{e});
                }
		elsif ($options{d}) {
			# delete a domain
			$pf->delDomain($options{d});
		}

		elsif ($options{f}) {
			# delete an alias
			$pf->delAlias($options{f});
		}
                else {
                        usageHelp();
                }
                 
                exit();
        }

        # modify user requires -c -v -e
        if ($options{m}) {

		if ($options{e} && $options{p}) {
			#update a password
			my $hash = $pf->hash($options{p}, 'md5crypt');
			$pf->modifyUser($options{e}, ['password'], [$hash]);
			exit();
		}
                if (!$options{e} || !$options{c} || !$options{v}) {
                        usageHelp();
                }
                my @cols = split(/, ?/, $options{c});
                my @vals = split(/, ?/, $options{v});

                $pf->modifyUser($options{e}, \@cols, \@vals);
                exit();
        }

        # add an alias requires -e
        if ($options{f}) {
                if (!$options{e}) {
                        usageHelp();
                }
		# again must be similar to setAliasCols
		# ['address', 'goto']
                $pf->addForward($options{f}, $options{e});
                exit();

        }

        # throw usage information
        usageHelp();
}

sub usageHelp {
print "USAGE\n"; 
print "---------------------------------------------------------------------------\n";
print "\t-a signify you want to add something\n";
print "\t-n specify user name\n";
print "\t-r signify you want to remove something\n";
print "\t-m signify you want to modify something\n";
print "\t-e <email> the email to do something with\n";
print "\t-p <password> the password to use when adding/modifying (clear text)\n";
print "\t-h <md5 hash> password as a hash\n";
print "\t-c <column1, column2, column3> columns to modify\n";
print "\t-v <value1, value2, value3> corrosponding values\n";
print "\t-f setup an alias to value in -e\n\n";
print "\t-q specify a quota when adding a user";

print "EXAMPLES\n";
print "---------------------------------------------------------------------------\n";
                        
print "Adding a user\n";
print "\t$0 -a -e test\@example.com -n \"Test User\" -p password\n";
print "\t$0 -a -e test\@example.com -n \"Hash Password\" -h 5f4dcc3b5aa765d61d8327deb882cf99\n\n";
                 
print "Modyfing a user\n";
print "\t$0 -m -e test\@example.com -c \"fname, email\" -v \"Test User, newtest\@example.com\"\n";
print "\t$0 -m -e test\@example.com -c \"quota\" -v 10\n\n";
 
print "Updating a password\n";
print "\t$0 -m -e test\@example.com -p newpassword\n\n";
                 
print "Create an alias\n";
print "\t$0 -f sales\@example.com -e test\@example.com\n\n";

print "Deleting things\n";
print "\t$0 -r -f alias\@blah.com\n";
print "\t$0 -r -d domain.com\n";
print "\t$0 -r -e user\@domain.com\n\n";
                
exit();
}
