PEPE_VERSION ?= 1.0.0
RPM_VER=$(PEPE_VERSION)
VERSION=${RPM_VER}
RELEASE=$(shell date +%y%m%d%H%M)
SERVICES=api chapolin munin acscollector

setup:
	git pull --recurse-submodules
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
		rm -f dists/pepe-$$service-${RPM_VER}*.rpm; \
	done

dist: package
	type fpm > /dev/null 2>&1 && \
  for service in ${SERVICES} ; do \
	  cd $$service; \
		echo "#version ${VERSION}" > target/VERSION && \
		git show --summary >> target/VERSION && \
		mkdir -p target/empty && \
		fpm -s dir \
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
				--after-install rpms/postinstall \
				--before-remove rpms/preremove \
				--after-remove rpms/postremove \
				-f -p ./dists/pepe-$$service-${RPM_VER}.el7.noarch.rpm \
								rpms/pepe-profile.sh=/opt/pepe/$$service/scripts/pepe.sh \
								rpms/pepe@.service=/usr/lib/systemd/system/pepe@.service \
								rpms/log4j.xml=/opt/pepe/$$service/conf/log4j.xml \
								target/VERSION=/opt/pepe/$$service/lib/VERSION \
								target/empty/=/opt/logs/pepe/$$service \
								target/pepe-$$service-${VERSION}-SNAPSHOT.jar=/opt/pepe/$$service/lib/pepe.jar; \
		cd -; \
  done

run:
	docker-compose up -d

stop:
	docker-compose stop -t1
	docker-compose rm -f

