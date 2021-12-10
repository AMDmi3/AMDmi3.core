CONTENT_DIR=	public

TIDY?=		tidy

all:: gen

gen::
	@rm -rf ${CONTENT_DIR}
	@hugo --destination=${CONTENT_DIR}

lint::
	-isort --check bin/contributions
	-flake8 --ignore=I,E501 bin/contributions
	-mypy bin/contributions

data/contributions.yaml::
	bin/contributions data/contributions.yaml

serve::
	@hugo serve -D

optipng::
	find content -name '*.png' | xargs -t -n1 -P4 optipng -q -o99

check:: gen
	@find ${CONTENT_DIR} -name "*.html" | while read f; do \
		${TIDY} \
			-quiet \
			-errors \
			--show-warnings yes \
			--show-filename yes \
			--mute-id yes \
			--mute TRIM_EMPTY_ELEMENT \
			--mute DISCARDING_UNEXPECTED \
			"$$f" || if [ $$? -gt 1 ]; then false; fi; \
	done
