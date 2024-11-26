BUILDDIR := $(shell ls -d build/cp3* 2>/dev/null | head -n 1)

.PHONY: build clean install test coverage stubs check

# https://mesonbuild.com/meson-python/how-to-guides/editable-installs.html
# editable install
install:
	make clean
	uv sync
	uv pip install -e . \
		--no-build-isolation \
		--force-reinstall \
		--config-settings=editable-verbose=true \
		# --config-settings=setup-args="-Db_coverage=true" \
		--config-settings=compile-args="-j8"

# quick build after having already setup the build directory
build:
	meson compile -C $(BUILDDIR)

# run tests (calling make install if needed)
test:
	@if [ -z "$(BUILDDIR)" ]; then \
		echo "Build directory not found. Running make install..."; \
		make install; \
	fi; \
	BUILDDIR=$$(ls -d build/cp3* 2>/dev/null | head -n 1); \
	if [ -z "$$BUILDDIR" ]; then \
		echo "Build directory still not found after install. Aborting."; \
		exit 1; \
	fi; \
	meson test -C $$BUILDDIR --verbose

# clean up build artifacts
clean:
	rm -rf build dist
	rm -rf coverage.info coverage.xml coverage_cpp.xml

coverage:
	rm -rf coverage coverage.xml coverage_cpp.xml
	mkdir coverage
	make test
	gcovr --xml coverage_cpp.xml --xml-pretty
	gcovr --html-details -o coverage/index.html --exclude .venv
	open coverage/index.html

check:
	pre-commit run --all-files --hook-stage manual
