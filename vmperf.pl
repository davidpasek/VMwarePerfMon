#!/usr/bin/perl -w
#
# Copyright (c) 2007 VMware, Inc.  All rights reserved.
# Copyright (c) 2012 Cloud4com, a.s.  All rights reserved.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use XML::LibXML;
use AppUtil::VMUtil;
use AppUtil::XMLInputUtil;
use Data::Dumper;

$Util::script_version = "1.0";

my %opts = (
   'vmname' => {
      type => "=s",
      help => "Name of virtual machine",
      required => 1,
   },
   'action' => {
      type => "=s",
      help => "action - show_counters, get_counters",
      required => 1,
   },
   'entity_type' => {
      type => "=s",
      help => "entity type - cpu,mem,net,disk",
      required => 0,
   },
   'entity_instance' => {
      type => "=s",
      help => "entity instance - 'scsi0:0', ...",
      required => 0,
   },
   'output' => {
      type => "=s",
      help => "Type of output - 'raw','prtg'",
      required => 0,
   },
   'output_format' => {
      type => "=s",
      help => "Ooutput format - comma separated list of counter names",
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate(\&validate);

# connect to the server
Util::connect();

my $action = Opts::get_option('action');
my $output = Opts::get_option('output');
my $output_format = Opts::get_option('output_format');
if (!defined($output)) {$output='raw';}
if (
    $output ne 'raw' &&
    $output ne 'prtg'
   ) 
{
  die "Unknown output";
}
if (
     $output eq 'prtg' && 
     !defined($output_format)) 
{
  die "The parameter 'output_format' must be used for 'prtg' output";
}

SWITCH:{

  if ($action eq 'show_counters')
    {
      &show_vm_perf_counters();
      last SWITCH;
    }

  if ($action eq 'get_counters')
    {
      &get_vm_perf_counters(type => Opts::get_option('entity_type'),
                            instance => Opts::get_option('entity_instance'));

      last SWITCH;
    }

  print "Unknown action.\n";
  print "Available actions are:\n";
  print "  show_counters\n";
  print "  get_counters\n";
}

Util::disconnect();

sub show_vm_perf_counters() {

  my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                            filter => {'name' => Opts::get_option('vmname') });

  if (!defined($vm_view)) {
    Util::trace(0,"VM name ".Opts::get_option('vmname')." not found.\n");
    return;
  }

  my $vmname = $vm_view->name;
  my $sc_view = Vim::get_service_content();
  my $perfmgr_view = Vim::get_view(mo_ref => $sc_view->perfManager);
  my $entity = $vm_view;
  my $perfCounterInfo = $perfmgr_view->perfCounter;
  my $availmetricid = $perfmgr_view->QueryAvailablePerfMetric(entity => $entity);

  print "VM: $vmname\n";

  my %ALL_COUNTERS = ();

  foreach (@$perfCounterInfo) {
    # print Dumper $_;
    # PerfCounterInfo
    my $key = $_->key;
    my $internal_name = $_->nameInfo->key;
    my $label = $_->nameInfo->label;
    my $summary = $_->nameInfo->summary;
    my $units = $_->unitInfo->label;
    my $group_type = $_->groupInfo->key;
    #print "Counter key: $key\n";
    #print "Counter internal name: $internal_name\n";
    #print "Counter label: $label\n";
    #print "Counter description: $summary\n";
    #print "Counter units: $units\n";
    #print "Counter group type: $group_type\n";
    #print "\n";
    $ALL_COUNTERS{$key}="$internal_name\n$label\n$summary\n$units\n$group_type";
  }

  foreach (@$availmetricid) {
    # print Dumper $_;
    # PerfMetricId
    my $counter_key = $_->counterId;
    my $counter_instance = $_->instance;
    print "Counter key: $counter_key\n";
    print "Counter instance: $counter_instance\n";
    print "Counter description:\n" . $ALL_COUNTERS{$counter_key} . "\n";
    print "\n";
  }
}

# GET VM PERFORMANCE COUNTERS
###############################
# get_vm_perf_counters (type=>'cpu', instance=>'');
# get_vm_perf_counters (type=>'mem', instance=>'');
# get_vm_perf_counters (type=>'net', instance=>'');
# get_vm_perf_counters (type=>'disk', instance=>'scsi0:0');
sub get_vm_perf_counters() {
  my %params = @_;
  my $type = $params{'type'};
  my $instance = $params{'instance'};
  if (!defined($instance)) {
    $instance = '';
  }

  my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                            filter => {'name' => Opts::get_option('vmname') });

  if (!defined($vm_view)) {
    Util::trace(0,"VM name ".Opts::get_option('vmname')." not found.\n");
    return;
  }

  # VM Name
  my $vmname = $vm_view->name;
  # VM number of vCPU
  my $vm_numcpu = 1;
  if (defined ($vm_view->summary->config->numCpu)) {
    $vm_numcpu = $vm_view->summary->config->numCpu; 
  }
  my $sc_view = Vim::get_service_content();
  my $perfmgr_view = Vim::get_view(mo_ref => $sc_view->perfManager);
  my $entity = $vm_view;

  my %perf_metric_id;

  # DEFINE REQUESTED PERFORMANCE COUNTERS
  SWITCH: {
    if (defined($type) && $type eq 'cpu') {
      # CPU MHz
      $perf_metric_id{6}={instance=>'',name=>'cpu_usage',unit=>'MHz'};
      # CPU Ready, millisecond
      $perf_metric_id{12}={instance=>'',name=>'cpu_ready',unit=>'ms'};
      last SWITCH;
    }
    if (defined($type) && $type eq 'mem') {
      # MEM Granted; KB
      $perf_metric_id{21}={instance=>'',name=>'mem_granted',unit=>'KB'};
      # MEM Active; KB
      $perf_metric_id{25}={instance=>'',name=>'mem_active',unit=>'KB'};
      # MEM Consumed; KB
      $perf_metric_id{90}={instance=>'',name=>'mem_consumed',unit=>'KB'};
      last SWITCH;
    }
    if (defined($type) && $type eq 'net') {
      # NET Data receive rate; KBps
      $perf_metric_id{120}={instance=>'',name=>'net_receive',unit=>'KBps'};
      # NET Data transmit rate; KBps
      $perf_metric_id{121}={instance=>'',name=>'net_transmit',unit=>'KBps'};
      last SWITCH;
    }
    if (defined($type) && $type eq 'disk') {
      # DISK Average read requests per second' number
      $perf_metric_id{134}={instance=>$instance,name=>'disk_read_iops',unit=>'num'};
      # DISK Average write requests per second' number
      $perf_metric_id{135}={instance=>$instance,name=>'disk_write_iops',unit=>'num'};
      # DISK Average read latemcy; millisecond
      $perf_metric_id{138}={instance=>$instance,name=>'disk_read_latency',unit=>'ms'};
      # DISK Average write latemcy; millisecond
      $perf_metric_id{139}={instance=>$instance,name=>'disk_write_latency',unit=>'ms'};
      last SWITCH;
    }
    do {
      print "&get_vm_perf_counters: Unknown type.\n";
      return;
    }
  }

  # DEFINE REQUESTED PERFORMANCE METRICS
  my @perf_metrics;
  foreach (keys(%perf_metric_id)) {
    my $counter_id = $_;
    my $counter_instance = $perf_metric_id{$counter_id}{instance};

    #print "Counter id: $counter_id\n";
    #print "Counter instance: $counter_instance\n";
    #print "Counter name: " . $perf_metric_id{$counter_id}{name} ."\n";
    #print "Counter unit: " . $perf_metric_id{$counter_id}{unit} ."\n";

    my $metric = PerfMetricId->new(
      counterId => $counter_id,
      instance  => $counter_instance,
    );

    push @perf_metrics, $metric;
  }

  # PREPARE PERFORMANCE QUERY SPECIFICATION
  my $perf_query_spec = PerfQuerySpec->new(
    entity => $vm_view,
    metricId => \@perf_metrics,
    format => 'csv',
    intervalId => 20,
    maxSample => 15
  );

  # GET PERFORMANCE DATA
  my $perf_data;
  eval {
      $perf_data = $perfmgr_view->QueryPerf( querySpec => $perf_query_spec);
  };
  if ($@) {
     if (ref($@) eq 'SoapFault') {
        if (ref($@->detail) eq 'InvalidArgument') {
           Util::trace(0,"Specified parameters are not correct");
        }
     }
     return;
  }
  if (! @$perf_data) {
     Util::trace(0,"Either Performance data not available for requested period "
                   ."or instance is invalid\n");
     my $intervals = get_available_intervals(perfmgr_view=>$perfmgr_view,
                                          vm => $vm_view);
     Util::trace(0,"\nAvailable Intervals\n");
     foreach(@$intervals) {
        Util::trace(0,"Interval " . $_ . "\n");
     }
     return;
   }

  # PARSE PERFORMANCE DATA AND PREPARE COUNTER DATA HASHES FOR SIMPLE OUTPUT
  my %COUNTER_VALUE;
  my %COUNTER_UNIT;
  foreach (@$perf_data) {
     my $time_stamps = $_->sampleInfoCSV;
     my $values = $_->value;
     foreach (@$values) {
        #my $counter_id = $_->id->counterId;
        my $counter_name = $perf_metric_id{$_->id->counterId}{name};
        my $counter_instance = $_->id->instance;
        my $counter_unit = $perf_metric_id{$_->id->counterId}{unit};
        my $counter_avg_value = &values_average($_->value);
        my $counter_name_instance_idx = $counter_name . '|' . $counter_instance;
   
        # implicit value & unit transformation 
        my ($t_counter_value,$t_counter_unit) = &counter_value_transformation(
           counter_name=>$counter_name,
           counter_value=>$counter_avg_value,
           counter_unit=>$counter_unit,
           vm_numcpu=>$vm_numcpu,
        );

        $COUNTER_VALUE{$counter_name_instance_idx} = $t_counter_value;
        $COUNTER_UNIT{$counter_name} = $t_counter_unit;
     }
  }

  # OUTPUT TYPE - RAW
  if ($output eq "raw") {
    foreach my $c (keys(%COUNTER_VALUE)) {
      my ($counter_name,$counter_instance) = split(/\|/,$c);
      my $counter_value = $COUNTER_VALUE{$c};
      my $counter_unit = $COUNTER_UNIT{$counter_name};
      print "Counter name instance index: " . $c . "\n"; 
      print "Counter name: " . $counter_name . "\n"; 
      print "Counter instance: " . $counter_instance . "\n"; 
      print "Counter avg value: " . $counter_value . "\n";
      print "Counter unit: " . $counter_unit . "\n";
      print "\n";
    }
  }

  # OUTPUT TYPE - PRTG - with defined output format
  if ($output eq "prtg") {
    my @OUTPUT_COUNTERS = split(/,/,$output_format);
    my $output_prtg = '';
    foreach my $c (@OUTPUT_COUNTERS) {
      #print "counter:$c\n";
      my $counter_index = $c . '|' . $instance;
      #print "counter index:$counter_index\n";
      my $counter_value = 'NULL';
      if (defined($COUNTER_VALUE{$counter_index})) {
        $counter_value = $COUNTER_VALUE{$counter_index};
      }
      #print "value:$counter_value\n";
      $output_prtg = $output_prtg . '[' . $counter_value . ']';
    }
    print $output_prtg;
  }
}

sub values_average {
  my ($values) = @_;
  my @values = split(/,/,$values);
  my $count = 0;
  my $sum = 0;
  foreach my $v (@values) {
    $count++;
    $sum = $sum + $v;
  }
  my $avg;
  if ($count==0) {
    $avg = 0;
  } else {
    $avg = $sum/$count;
  }
  #print "Count : $count\n";
  #print "Sum   : $sum\n";
  #print "Avg   : $avg\n";
  return $avg;
}

# TRANSFORMATION
#
#my (t_value,t_unit) = counter_value_transformation(
#           counter_name=>$counter_name,
#           counter_value=>$counter_avg_value,
#           counter_unit=>$counter_unit,
#        );
sub counter_value_transformation {
  my %params = @_;
  my $counter_name = $params{'counter_name'};
  my $counter_value = $params{'counter_value'};
  my $counter_unit = $params{'counter_unit'};
  my $vm_numcpu = $params{'vm_numcpu'};

  #CPU_READY
  if ($counter_name eq 'cpu_ready') {
    $counter_value = ($counter_value/(20*1000)*100);
    $counter_value = $counter_value / $vm_numcpu;
    $counter_unit = '%';
  }

  #DISK_READ_LATENCY
  if ($counter_name eq 'disk_read_latency') {
    if ( ($counter_value < 0) || ($counter_value > 100) ) {
      $counter_value = 0;
    }
  }

  #DISK_WRITE_LATENCY
  if ($counter_name eq 'disk_write_latency') {
    if ( ($counter_value < 0) || ($counter_value > 100) ) {
      $counter_value = 0;
    }
  }

  return ($counter_value,$counter_unit);
}


sub validate {
  my $valid = 1;
  return $valid;
}
