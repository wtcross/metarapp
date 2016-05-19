def commit_id

stage 'Build and Publish'
node(){

    // COMPILE AND JUNIT
    
    //use git checkout
    checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/hdharia/metarapp.git']]])

	sh('pwd')
	sh('git rev-parse HEAD > GIT_COMMIT')
    commit_id=readFile('GIT_COMMIT')	
    echo "COMMIT_ID ${commit_id}"    
    
    ensureMaven()
    sh 'mvn clean install'
    stash includes: 'deployments/ROOT.war', name: 'war'
    step $class: 'hudson.tasks.junit.JUnitResultArchiver', testResults: 'target/surefire-reports/*.xml'
    echo "INFO - Ending build phase"
    
     docker.withServer('unix:///var/run/docker.sock'){

        def metarappImage = docker.build "hdharia/metarapp-wildfy-app:${env.BUILD_NUMBER}"
       
        sh "docker -v"
        //use withDockerRegistry to make sure we are logged in to docker hub registry
        withDockerRegistry(registry: [credentialsId: 'docker-hub-hdharia17']) { 
          metarappImage.push()
        }
   }
}

checkpoint "Build Complete"

stage 'Dev Deploy via Ansible'
node()
{
	echo "Deploying to Dev"
	unstash 'war'
	
	echo "Launching Dev Server for ${commit_id}"
	
	//Ansible call to standup dev environment
    
    //Call Ansible
    sh "tower-cli job launch --job-template=62 --extra-vars=\"commit_id=${commit_id}\""
    
    stage "Verify DEV Deployment"
	timeout(time: 20, unit: 'MINUTES')
	{
	   try
	   { 
	      input message: 'Dev Deployment Verified'
	   } 
	   catch(Exception e)
	   {
	      echo "No input provided, resuming build"
	   } 
	}
		
	echo "Deployed to Dev"
}

checkpoint "Deployed and Verified at Dev"

stage name: 'Quality analysis and Perfs'
parallel(qualityAnalysis: {

    node(){
        // RUN SONAR ANALYSIS
        echo "INFO - Starting SONAR"
        ensureMaven()
        //sh 'mvn -o sonar:sonar'
        echo "INFO - Ending SONAR"
    }
}, performanceTest: {

    node(){
        // DEPLOY ON PERFS AND RUN JMETER STRESS TEST
        echo "INFO - starting Perf Tests"
        //sh 'mvn -o jmeter:jmeter'
        echo "INFO - Ending Perf Tests"
    }
}
)

stage 'Tear Down DEV'
node()
{
	echo "Tear Down DEV"	
	    
    //Call Ansible
    sh "tower-cli job launch --job-template=63 --extra-vars=\"commit_id=${commit_id}\""
}

checkpoint "QA analysis complete"

stage "Approval for QA Deploy"
timeout(time: 10, unit: 'MINUTES')
{
   try
   { 
      input message: 'Deploy to QA?'
   } 
   catch(Exception e)
   {
      echo "No input provided, resuming build"
   } 
}

stage 'QA Deploy via Ansible'
node()
{
	echo "Deploying to QA"
	
 	//Call Ansible
    sh "tower-cli job launch --job-template=62 --extra-vars=\"commit_id=${commit_id}\""	

    stage "Verify DEV Deployment"
	timeout(time: 20, unit: 'MINUTES')
	{
	   try
	   { 
	      input message: 'Dev Deployment Verified'
	   } 
	   catch(Exception e)
	   {
	      echo "No input provided, resuming build"
	   } 
	}
		
	echo "Deployed to QA"
}

checkpoint "Deployed to QA"

stage 'Tear Down QA'
node()
{
	echo "Tear Down QA"	
	timeout(time: 20, unit: 'MINUTES')
	{
	   try
	   { 
	      input message: 'QA Test Completed, Tear Down QA'
	   } 
	   catch(Exception e)
	   {
	      echo "No input provided, resuming build"
	   } 
	}    
    //Call Ansible
    sh "tower-cli job launch --job-template=63 --extra-vars=\"commit_id=${commit_id}\""
}

stage 'Approval for Staging Deploy'
timeout(time: 60, unit: 'SECONDS')
{
   try
   {
    input message: "Deploy to Staging?"
   } 
   catch(Exception e)
   {
      echo "No input provided, resuming build"
   } 
}

stage 'Staging Deploy'
node()
{
	echo "Deploying to Staging"
	
	//Hook in openshift deployment
	wrap([$class: 'OpenShiftBuildWrapper',
                url: 'https://openshift.beesshop.org:8443',
                credentialsId: 'openshift-admin-aws',
                insecure: true, //Don't check server certificate
                ]) {
 
                // oc & source2image
                sh """
                oc project movieplex-application
                oc start-build j2ee-application-build
                """
        }
	
	echo "Deployed to Staging"
}

checkpoint "Deployed to Staging"
stage 'Approval for Production Deploy'
timeout(time: 60, unit: 'SECONDS')
{
   input message: "Deploy to Prod?"
}

stage 'Deploy to Production'
node()
{
	echo "Deploying to Prod"
	
	//Hook into oepnshift deployment
	wrap([$class: 'OpenShiftBuildWrapper',
                url: 'https://openshift.beesshop.org:8443',
                credentialsId: 'openshift-admin-aws',
                insecure: true, //Don't check server certificate
                ]) {
 
                // oc & source2image
                sh """
                oc project movieplex-application
                oc start-build j2ee-application-build
                """
        }
	
	echo "Deployed to Prod"
}

/**
 * Deploy Maven on the slave if needed and add it to the path
 */
def ensureMaven() {
    env.PATH = "${tool 'mvn'}/bin:${env.PATH}"
}