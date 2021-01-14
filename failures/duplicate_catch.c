int main() {
    throw Foo(NULL);
    throw _(NULL); //!wildcard//

    try {}
    catch (Foo _) {}
    catch (Bar _) {}
    catch (Bar _) {} //?duplicate//
    catch (Foo _) {} //?duplicate//
    catch (_ _) {}
    catch (Baz _) {} //?unreachable//
    catch (Quux _) {} //?unreachable//

    try {}
    catch (Foo _) {}
    catch (Foo _) {} //?duplicate//
}
