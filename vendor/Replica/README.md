# MAD STUDIO - Replica

Replica is a Roblox server to client state replication solution which lets the developer subscribe certain players to certain states.

Individual states in the Replica module are called "replicas". Replicas can only be created and changed server-side, both server
and client can connect cleanup tasks for the moment of replica destruction, state changes can trigger listeners on the client-side.