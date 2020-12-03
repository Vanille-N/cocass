int main() {
    try {
        if (1) {
            throw Foo(NULL);
        } else {
            throw _(NULL);
        }
    } catch (Foo _) {
        return 1;
    } catch (Bar _) {
        return _;
    } catch (Foo _) {
        return 3;
    } catch (_ _) {
        return 4;
    } catch (Baz _) {
        return 4;
    }
}
