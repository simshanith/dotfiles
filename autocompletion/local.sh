if [[ -d "/usr/local/etc/bash_completion.d/" ]]; then
	for f in /usr/local/etc/bash_completion.d/*; do
		source $f;
	done
fi
