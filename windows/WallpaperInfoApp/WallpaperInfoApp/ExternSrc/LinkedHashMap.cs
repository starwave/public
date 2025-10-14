using System;
using System.Collections.Generic;

public class LinkedHashMap<K, V> {
	public Dictionary<K, LinkedListNode<Tuple<V, K>>> DIC = new Dictionary<K, LinkedListNode<Tuple<V, K>>>();
	public LinkedList<Tuple<V, K>> LL = new LinkedList<Tuple<V, K>>();
	public LinkedHashMap<K, V> Clone() {
		LinkedHashMap<K, V> new_copy = new LinkedHashMap<K, V>();
		new_copy.DIC =  new Dictionary<K, LinkedListNode<Tuple<V, K>>>(this.DIC);
		new_copy.LL =  new LinkedList<Tuple<V, K>>(this.LL);
		return new_copy;
	}
	public LinkedList<Tuple<V, K>> Items() {
		return LL;
	}
	public V this[K k] {
		get {
            if (DIC.ContainsKey(k)) {
                return DIC[k].Value.Item1;
            } else {
                return default(V);
            }
		}
		// better to update the value rather than delete and addlast
		set {
			if (DIC.ContainsKey(k)) {
				LL.Remove(DIC[k]);
			}
			DIC[k] = new LinkedListNode<Tuple<V, K>>(Tuple.Create(value, k));
			LL.AddLast(DIC[k]);
		}
	}
	public K Get(int index) {
		if (index < 0 || index > LL.Count - 1) {
			Console.WriteLine("Asset - Shouldn't ask out of bound of LinkedHashMap");
			return default(K);
		}
		var count = 0;
		foreach (var item in LL) {
			if (count == index) {
				return item.Item2;
			}
			count++;
		}
        return default(K);
    }
	public bool Contains(K k) {
		return DIC.ContainsKey(k);
	}
	public void Put(K k, V u) {
		this[k] = u;
	}
	public bool Remove(K k) {
		if (DIC.ContainsKey(k)) {
			LL.Remove(DIC[k]);
            DIC.Remove(k);
			return true;
		}
		return false;
	}
	public void RemoveAll() {
		LL.Clear();
        DIC.Clear();
	}
	public V DropFirst() {
		var node = LL.First;
		LL.Remove(node);
		DIC.Remove(node.Value.Item2);
		return node.Value.Item1;
	}
	public int Count {
		get {
			return DIC.Count;
		}
	}
	public int FirstIndexOf(K k) {
        var index = 0;
        for (var node = LL.First; node != null; node = node.Next, index++) {
            if (k.Equals(node.Value.Item2)) {
				return index;
			}
        }
		return -1;
	}
	public void RemoveAt(int index) {
		var k = Get(index);
		// intentionally make it crash  if it's out of bound
		Remove(k);
	}
	public void AddFirst(K k, V v) {
		if (DIC.ContainsKey(k)) {
			LL.Remove(DIC[k]);
		}
		DIC[k] = new LinkedListNode<Tuple<V, K>>(Tuple.Create(v, k));
		LL.AddFirst(DIC[k]);
	}
}

