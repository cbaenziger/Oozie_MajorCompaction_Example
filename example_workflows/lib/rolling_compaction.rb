#!/usr/bin/hbase shell
require 'set'
include Java
import org.apache.hadoop.hbase.HBaseConfiguration
import org.apache.hadoop.hbase.TableName
import org.apache.hadoop.hbase.client.ConnectionFactory
import org.apache.hadoop.hbase.client.HBaseAdmin
import org.apache.hadoop.hbase.ServerName
import org.apache.hadoop.hbase.client.HTable
import org.apache.hadoop.hbase.HRegionInfo

@CONF = HBaseConfiguration.new()
@CONN = ConnectionFactory.createConnection(@CONF)
@ADMIN = @CONN.getAdmin()
@CS = @ADMIN.getClusterStatus()

# returns a hash of key ServerName with a hash of weights
# (higher is more urgent) with an array of region bytes
# Arguments: table - a string for table name
#            include_zero - to include regions with a balance weight of zero
def generate_compaction_plan(table, include_zero)
  # find all primary regions' servers
  t = HTable.new(@CONF, TableName.valueOf(table))
  primary_regions = t.getRegionLocator().getAllRegionLocations().to_a
  primary_regions.reject! { |region_locator| region_locator.getRegionInfo().replicaId != 0 }
  # make primary_region_names a set for faster include? look-ups elsewhere
  primary_region_names = Set.new(primary_regions.map { |rl| rl.getRegionInfo().getRegionNameAsString() })
  servers = primary_regions.map { |region_locator| region_locator.getServerName() }
  servers.uniq!
  
  regions_to_compact = Hash.new
  
  # compute the compaction weight for all servers this table is hosted on
  servers.each do |sn|
    region_loads = @CS.getLoad(sn).getRegionsLoad()
    regions = Hash.new
    region_loads.each do |name, rl|
      next unless primary_region_names.include?(rl.getNameAsString())

      weight = compaction_weight(rl)
      (next if weight <= 0) unless include_zero
      regions[weight] = regions.fetch(weight, Array.new).push(rl.getName())
    end
    regions_to_compact[sn] = regions
  end

  regions_to_compact
end

# computes a weight for how important this region is to compact
# * zero is used to flag no need to compact
# * higher is more in need of compaction - there is no scale
# Argument: An org.apache.hadoop.hbase.RegionLoad 
# Returns: A number from 0 to inf
def compaction_weight(region_load)
  (region_load.getStorefiles() - 1) * region_load.getStorefileSizeMB()
end

# Initiate a rolling_compaction
# Arguments: table - string name of the table to compact
#            force_compaction - to force compaction of all regions - e.g. for data locality
#                               (otherwise those with weight 0 are skipped)
def rolling_compaction(table, force_compaction)
  cp = generate_compaction_plan(table, force_compaction)

  puts "Regions to compact for table %s:" % table
  cp.each do |server, reg_hash|
    puts "%s has %s region(s) to compact" % [server, [0, reg_hash.map {|weight, vals| vals.length}.inject(:+)].compact.max]
  end

  start_time = Time.now.to_f * 1000

  # loop over regions until we have worked through entire compaction plan
  until cp.empty?
    # strip servers as we remove all regions
    cp.reject! {|server, reg_hash| reg_hash.empty?}
    # compact a new region
    cp.each do |server, reg_hash|
      highest_weight = reg_hash.keys.sort.reverse.last
      region = reg_hash[highest_weight].last()
      if (@ADMIN.getLastMajorCompactionTimestampForRegion(region) > start_time or
          @ADMIN.getLastMajorCompactionTimestampForRegion(region) == 0)
        puts "Compacted %s region %s" % [server.toString(), HRegionInfo.encodeRegionName(region)]
        reg_hash[highest_weight].pop()
        # remove this weight if the last entry
        reg_hash.delete(highest_weight) if reg_hash[highest_weight].empty?
      elsif @ADMIN.getCompactionStateForRegion(region).toString() == 'NONE'
        puts "Compacting %s region %s" % [server.toString(), HRegionInfo.encodeRegionName(region)]
        @ADMIN.majorCompactRegion(region)
      end
    end
    sleep(0.25)
  end
  puts "Done compacting in %s seconds" % (Time.now.to_f - start_time/1000)
end

# Equivalent of
# if __FILE__ == $0
if ENV.fetch('table_name', false)
  rolling_compaction(ENV.fetch('table_name'), ENV.fetch('force_compaction', false))
  exit
end
