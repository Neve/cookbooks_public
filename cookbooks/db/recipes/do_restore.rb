# Cookbook Name:: db
#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

rs_utils_marker :begin

DATA_DIR = node[:db][:data_dir]

raise 'Database already restored.  To over write existing database run do_force_reset before this recipe' if node[:db][:db_restored] 

log "  Running pre-restore checks..."
db DATA_DIR do
  action :pre_restore_check
end

log "======== LINEAGE ========="
log node[:db][:backup][:lineage]
log "======== LINEAGE ========="

# ROS restore requires a setup, but VOLUME restore does not.
# Only Rackpspace uses ROS backups
if node[:cloud][:provider] == "rackspace"
  log "  Creating block device..."
  block_device DATA_DIR do
    lineage node[:db][:backup][:lineage]
    action :create
  end
end

log "  Stopping database..."
db DATA_DIR do
  action :stop
end

log "  Performing Restore..."
# Requires block_device node[:db][:block_device] to be instantiated
# previously. Make sure block_device::default recipe has been run.
block_device DATA_DIR do
  lineage node[:db][:backup][:lineage]
  timestamp_override node[:db][:backup][:timestamp_override]
  action :restore
end

log "  Running post-restore cleanup..."
db DATA_DIR do
  action :post_restore_cleanup
end

log "  Starting database as master..."
db DATA_DIR do
  action [ :start, :status ]
end

# TODO: replication not yet supported
# log "  Setup replication grants..."
# db DATA_DIR do
#   action [ :set_replication_grants ]
# end

ruby_block "Setting db_restored state to true" do
  block do
    node[:db][:db_restored] = true
  end
end

rs_utils_marker :end
