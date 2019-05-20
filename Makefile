PEPE_VERSION ?= 1.0.0
RPM_VER=$(PEPE_VERSION)
VERSION=${RPM_VER}
RELEASE=$(shell date +%Y%m%d%H%M)
SERVICES=api chapolin munin

setup:
	git pull --recurse-submodules
	git submodule update --remote --recursive
	cd st2; make env; cd -

common: clean
	cd common && PEPE_VERSION=${PEPE_VERSION} ./mvnw install -DskipTests && cd -

package: common
	PEPE_VERSION=${PEPE_VERSION} ./mvnw package -DskipTests

test: clean
	PEPE_VERSION=${PEPE_VERSION} ./mvnw test

clean: setup
	PEPE_VERSION=${PEPE_VERSION} ./mvnw clean
	for service in ${SERVICES} ; do \
		rm -vf $$service/dists/pepe-$$service-${RPM_VER}*.rpm; \
	done

dist: package
	bundle lock && \
	bundle install --deployment && \
	bundle exec type fpm > /dev/null 2>&1 && \
  for service in ${SERVICES} ; do \
		echo "#version ${VERSION}" > $$service/target/VERSION && \
		cd $$service && git show --summary >> target/VERSION && cd - && \
		mkdir -p $$service/target/empty && \
		bundle exec fpm -s dir \
				--rpm-rpmbuild-define '_binaries_in_noarch_packages_terminate_build 0' \
				-t rpm \
				-n "pepe-$$service" \
				-v ${RPM_VER} \
				--iteration ${RELEASE}.el7 \
				-a noarch \
				--rpm-os linux \
				-m 'A-Team <a-team@corp.globo.com>' \
				--url 'https://pepeproject.github.com' \
				--vendor 'Globo.com' \
				--description "Pepe $$service service" \
				--after-install $$service/rpms/postinstall \
				--before-remove $$service/rpms/preremove \
				--after-remove $$service/rpms/postremove \
				-f -p ./$$service/dists/pepe-$$service-${RPM_VER}-${RELEASE}.el7.noarch.rpm \
						$$service/rpms/pepe-profile.sh=/opt/pepe/$$service/scripts/pepe.sh \
						$$service/rpms/pepe@.service=/usr/lib/systemd/system/pepe@.service \
						$$service/rpms/log4j.xml=/opt/pepe/$$service/conf/log4j.xml \
						$$service/target/VERSION=/opt/pepe/$$service/lib/VERSION \
						$$service/target/empty/=/opt/logs/pepe/$$service \
						$$service/target/pepe-$$service-${VERSION}-SNAPSHOT.jar=/opt/pepe/$$service/lib/pepe.jar; \
  done

stanley:
	docker create --name tempst2 stackstorm/stackstorm:latest && \
	docker cp tempst2:/home/stanley/.ssh/stanley_rsa . && \
	docker rm tempst2

run: stanley
	docker-compose up -d

stop:
	rm -f stanley_rsa
	docker-compose stop -t1
	docker-compose rm -f
	docker network prune -f

volume-prune:
	docker volume prune -f

