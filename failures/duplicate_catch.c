int main() {
    throw Foo(NULL);
    throw _(NULL); //!

    try {}
    catch (Foo _) {}
    catch (Bar _) {}
    catch (Bar _) {} //?
    catch (Foo _) {} //?
    catch (_ _) {}
    catch (Baz _) {} //?
    catch (Quux _) {} //?

    try {}
    catch (Foo _) {}
    catch (Foo _) {} //?
}
