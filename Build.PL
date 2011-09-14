use Module::Build;

Module::Build -> new
(
 module_name    => 'DateTime::Format::Gedcom',
 license        => 'artistic',
 dist_abstract  => 'Parse GEDCOM dates',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
 	 Test::More => 0.94,
 	 Test::Pod  => 1.44,
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
	 DateTime                  => 0.70,
	 DateTime::Format::Natural => 0.90,
	 DateTime::Infinite        => 0.70,
	 Hash::FieldHash           => 0.10,
	 Try::Tiny                 => 0.11,
 },
) -> create_build_script();
