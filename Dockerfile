FROM jboss/wildfly

ENV MYSQL_DATABASE
ENV MYSQL_USER
ENV MYSQL_PASSWORD

ADD deployments/ROOT.war /opt/jboss/wildfly/standalone/deployments/