

############ >>> java application
function javainit {
  gradle init --project-name demo --package demo --type java-application --dsl groovy --test-framework junit-jupiter

}
############ >>> Springboot
# 2.6.4-SNAPSHOT
function springinit {
cat <<'EOF'
spring init \
--artifactId=sample-project \
--groupId=app \
--bootVersion=2.7.1 \
--javaVersion=17 \
--language=java \
--type=gradle-project \
--packageName=app \
--name=Application \
--dependencies=lombok,web,data-jpa,postgresql \
sample-project

more info 
$ spring init --list
https://start.spring.io/

Notes. 
If you use Selenide 5.25.0 then --bootVersion=2.6.4-SNAPSHOT.

if you use dynamodb
    gradle.build dependencies 
        implementation group: 'software.amazon.awssdk', name: 'dynamodb-enhanced', version: '2.17.100'
EOF
}