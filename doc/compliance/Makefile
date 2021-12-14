generate:
	trestle author ssp-generate -p gitlab -o dist/system-security-plans/gitlab -y status_header.yaml

assemble:
	trestle author ssp-assemble --markdown dist/system-security-plans/ --output gitlab

status:
	grep -R "\- c\-" dist/system-security-plans/* | cut -d':' -f2 | sort | uniq -c
