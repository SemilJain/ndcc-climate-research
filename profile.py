"""This is a trivial example of a gitrepo-based profile; The profile source code and other software, documentation, etc. are stored in in a publicly accessible GIT repository (say, github.com). When you instantiate this profile, the repository is cloned to all of the nodes in your experiment, to `/local/repository`. 

This particular profile is a simple example of using a single raw PC. It can be instantiated on any cluster; the node will boot the default operating system, which is typically a recent version of Ubuntu.

Instructions:
Wait for the profile instance to start, then click on the node in the topology and choose the `shell` menu item. 
"""

# Import the Portal object.
import geni.portal as portal

# Import the ProtoGENI library.
import geni.rspec.pg as pg

# Create a portal context.
pc = portal.Context()

# Describe the parameter(s) this profile script can accept.
# pc.defineParameter( "dataset", "Dataset to use", portal.ParameterType.STRING, "sandy")
pc.defineParameter(
    "dataset","Dataset to use",portal.ParameterType.STRING,
    'sandy',[('sandy','Hurricane Sandy Case (27 Oct 2012)'),('snow','Snow Case (23 Jan 2016)'),
           ('derecho','Derecho Case (29 Jun 2012)')],
    longDescription="Specifies the dataset to use for running the model and getting results!")


# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()
 
# Add a raw PC to the request.
node = request.RawPC("node")

# Check parameter validity. Should fetch the dataset from the long-term volume

# if params.dataset == "sandy":
#     pc.reportError( portal.ParameterError( "Sandy dataset is not available right now" , ["dataset"]) )

# Allocate a node and ask for a 30GB file system mounted at /mydata
node.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU16-64-STD"

iface = node.addInterface()
fsnode = request.RemoteBlockstore("fsnode", "/mydata")
fsnode.dataset = "urn:publicid:IDN+utah.cloudlab.us:ndcc-pg0+ltdataset+ndcc-datasets"

fsnode.readonly = True

fslink = request.Link("fslink")
fslink.addInterface(iface)
fslink.addInterface(fsnode.interface)

# Special attributes for this link that we must use.
fslink.best_effort = True
fslink.vlan_tagging = True

# bs = node.Blockstore ("bs", "/mydata")
# bs.size = "30GB"

# Install and execute a script that is contained in the repository.
node.addService(pg.Execute(shell="sh", command="touch /local/repository/silly.sh"))


# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)