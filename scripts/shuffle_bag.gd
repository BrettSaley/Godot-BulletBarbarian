class_name ShuffleBag
## Deals every option once, in random order, before any repeats. `queue` holds
## what's left of the current round and is refilled when it runs out; a new
## round never starts with `last`, so nothing comes up twice in a row.

static func next(queue: Array, options: Array, last = null):
	if queue.is_empty():
		queue.append_array(options)
		queue.shuffle()
		if queue.size() > 1 and queue[0] == last:
			queue.push_back(queue.pop_front())
	return queue.pop_front()
