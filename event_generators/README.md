### Event Generators

Allow for easily re-running `event_generators.pl` with updates to time/etc

Example run:

    ./generate_events.pl < event_generators/2021/2021_10_09_Izumi_Tamagawa.txt

Create a new generator:

    ./generate_events.pl
    (fill in blanks)
    (extract generator from end of yyyy_mm_dd_log.txt)

Bold Life Tribe generators

* pull in title data from rpl/BLTConstants.pm
* TODO: pull Description paragraph from carefully named files
* TODO: pull image URL from somewhere
