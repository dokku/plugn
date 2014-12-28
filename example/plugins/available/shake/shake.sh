
shake() {
	declare desc="Shake the vending machine"
	echo "SHAKE SHAKE"
	echo "==== ITEM ===="
	cat $stuck_file
	echo "=============="
	> $stuck_file
}

cmd-export shake