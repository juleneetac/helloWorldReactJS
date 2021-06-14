def repoName = ""
pipeline {

    agent {
        label 'seapdl-nodejs14'
    }

    environment {
        SONAR_TOKEN = credentials("${PROJECT}-sonar-token")
        SONAR_PROJECT = "${PROJECT}-${APP}"
        VERSION = ""
        NEXUS_AUTH = credentials("${PROJECT}-nexus-credentials")
        NEXUS_USERNAME = "${NEXUS_AUTH_USR}"
        NEXUS_PASSWORD = "${NEXUS_AUTH_PSW}"
        HOME = '.'
    }
    stages {

        stage('Build App') {
            steps {
                container('seapdl-nodejs14'){
                    echo "==== Build App Stage ===="
                     script {
                        PWD = sh ( script: 'pwd', returnStdout: true).trim()
                        sh "echo ${PWD}"
                        sh "ls -ltr"
                        sh "npm install"
                        sh "ls -ltr"

                    }
                    sh "npm --version"
                    sh "node -v"
                }
            }
        }

        // stage('Lint & Test app') {
        //     steps {
        //         container('seapdl-nodejs14'){
        //             echo "==== Test App Stage ===="
        //             script {
        //                 PWD = sh ( script: 'pwd', returnStdout: true).trim()
        //                 sh "npm install"
        //                 sh "npm test"  
        //                 sh "q"
        //             }

        //         }
        //     }
        // }

        // stage('Analyze Code ') {
        //     steps {
        //     container('seapdl-sonar-scanner'){
        //             echo "==== Analyze App Stage ===="
        //             script {
        //                 sh "sonar-scanner -Dsonar.host.url=http://sonarqube-nexson.192.168.99.110.nip.io -Dsonar.login=${SONAR_TOKEN} -Dsonar.projectName=${SONAR_PROJECT} -Dsonar.projectKey=${SONAR_PROJECT}"
        //             }
        //         }
        //     }
        // }


        stage('Validate Dockerfile') {
            steps {
                container('python') {
                    echo "==== Validate Dockerfile ===="
                    script {
                        PWD = sh ( script: 'pwd', returnStdout: true).trim()
                        sh "echo ${PWD}"
                        sh "ls -ltr"
                        try {
                            sh "cd /opt/scanner/dockerfile/ && python3 scanDockerfile.py -a ${PWD}/Dockerfile"
                        } catch(err) {
                            echo err.getMessage()
                            echo "Docker validation script found some errors, review them. The pipeline continues..."
                        }

                    }
                }
            }
        }

        stage('Validate Template') {
            steps {
                container('python') {
                    echo "==== Validate Template ===="
                    script {
                        PWD = sh ( script: 'pwd', returnStdout: true).trim()
                        sh "echo ${PWD}"
                        sh "ls -ltr"
                        try {
                            sh "cd /opt/scanner/deploy/ && python3 scanDeployment.py ${PWD}/app.yaml"
                        } catch(err) {
                            echo err.getMessage()
                            echo "Deploy validation script found some errors, review them. The pipeline continues..."
                        }

                    }
                }
            }
        }


        // stage('Deploy zip to Nexus') {
        //     steps {
        //         script {
        //             openshift.withCluster() {
        //                 openshift.withProject("${PROJECT}") {
        //                     def template = openshift.apply(readFile('app.yaml'))
        //                     def model = openshift.process(template.name(), "-p", "PROJECT=${PROJECT}", "APP=${APP}")

        //                 }
        //             }
        //         }

        //         container('python') {
        //             echo "==== Deploy Nexus Artifact Stage ===="

        //             script {
        //                 VERSION = sh ( script: "cat package.json   | grep version   | head -1  | awk -F: '{ print \$2 }' | sed 's/[\",]//g' ", returnStdout: true).trim()
        //                 echo VERSION
        //                 echo env.VERSION
        //                 def projectVar = env.PROJECT
        //                 echo projectVar
        //                 repoName = projectVar+"-RELEASES"
        //                 echo repoName
        //              }
        //             sh "echo ${VERSION}"
        //             sh "echo ${repoName}"

        //             sh "zip -r '$APP'-'$VERSION'.zip  ."
        //             sh "curl --header 'Content-Type: application/x-7z-compressed' --upload-file '$APP'-'$VERSION'.zip -u '$NEXUS_USERNAME':'$NEXUS_PASSWORD' -v 'http://nexus-nexson.192.168.99.110.nip.io/repository/$repoName/'"
        //         }
        //     }
        // }


        stage('Create image builder') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject("${PROJECT}") {
                            return !openshift.selector("bc", "${APP}").exists();
                        }
                    }
                }
            }
            steps {
                echo "==== Create Image Builder Stage ===="

                script {

                    openshift.withCluster() {

                        openshift.withProject("${PROJECT}") {
                            // Will use default image if Dockerfile does not exists or if the file has no FROM instruction
                            // def dockerImage = 'registry.access.redhat.com/openshift3/ose-docker-builder:v3.11'

                            // if (fileExists('Dockerfile'))
                            //     readFile('Dockerfile').split('\n').find { l -> !l.startsWith("#") && l.contains("FROM") }.with { if (it) dockerImage = (it - 'FROM').trim() }
                            openshift.newBuild("--name=${APP}", "-l app=${APP}", "--strategy=docker", "--binary=true", "--to=${APP}:latest")
                            //el --binary=true hay unas restricciones que fuerza 
                        }
                    }
                }
            }
        }


        stage('Build image') {
            steps {
                echo "==== Build Image Stage ===="

                sh "rm -rf oc-build && mkdir oc-build && mkdir oc-build/public && mkdir oc-build/src"
                sh "cp Dockerfile oc-build/Dockerfile"
                //sh "cp nginx.conf oc-build/nginx.conf"  //añadido nuevo
                sh "cp package.json oc-build/package.json"
                sh "cp public/index.html oc-build/public/index.html"
                sh "cp src/index.js oc-build/src/index.js"
                

                //sh "mv public oc-build/public"
                //sh "ls oc-build/dist/react-nginx-docker"

                script {
                    openshift.withCluster() {
                        openshift.withProject("${PROJECT}") {
                            openshift.selector("bc", "${APP}").startBuild("--from-dir=oc-build", "--wait=true")
                        }
                    }
                }
            }
        }

        stage('Deploy app') {
            steps {
                echo "==== Deploy app Stage ===="

                script {
                    openshift.withCluster() {
                        openshift.withProject("${PROJECT}") {
                            def template = openshift.apply(readFile('app.yaml'))
                            def model = openshift.process(template.name(), "-p",
                                    "PROJECT=${PROJECT}", "APP=${APP}")


                            def dc = openshift.apply(model).narrow('dc')
                            dc.rollout().latest()
                            timeout(10) {
                                dc.rollout().status('-w')
                            }
                        }
                    }
                }
            }
        }
    }
}