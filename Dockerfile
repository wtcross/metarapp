FROM jboss/wildfly
ADD deployments/ROOT.war /opt/jboss/wildfly/standalone/deployments/
