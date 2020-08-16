# Programming Language oak
oak is a functional-like programming language influenced by D, OCaml.

Currently implementing semantic phase....

## To Do
* Semantic Analysis
* Type Checker

## oak Source Example
```
module main;
 
func factorial:int n:int = 
    when n > 0 : n * factorial (n-1)
    else 1;
 
struct Vector3 {
    let x:real32,
        y:real32,
        z:real32;
}
 
func addvec3:Vector3 v:Vector3 w:Vector3 {
    let result:Vector3;
    result.x = v.x + w.x;
    result.y = v.y + w.y;
    result.z = v.z + w.z;
    return result;
}
 
 
func main {
    writeln (factorial 5);	// 120
    writeln ( addvec3 Vector3(0.1, 0.3, -2.1) Vecotr3(0.5, -1.5, 3.8) );	// Vector3(0.6, -1.2, 1.7)
}
```
 
